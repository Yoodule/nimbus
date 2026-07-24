#!/usr/bin/env python3
# scripts/pagefind_hook.py
#
# mkdocs hook: invoked by `mkdocs build` on every run (including the
# build triggered by `mkdocs gh-deploy`). Runs `pagefind` against the
# freshly built site/ so per-locale search shards are guaranteed to be
# in the deployed artifact.
#
# Why this is a hook, not a post-build shell step in deploy-docs.sh:
#   `mkdocs gh-deploy` always runs its own `mkdocs build` before
#   pushing. Any site/ we pagefind ahead of that build is wiped by the
#   embedded build. The hook runs *inside* the embedded build, so the
#   shards land in the same site/ tree that gets pushed to gh-pages.
#
# Why we shell out to `uvx` instead of importing the pagefind Python
# package: the standard install path is `npx pagefind` (Node) or
# `uvx --from pagefind[extended] python -m pagefind` (Python). uv is
# already on PATH from the Nimbus install script; using the same
# launcher here means the dev environment and CI deploy use the same
# binary. The [extended] extra is required for CJK segmentation; the
# non-extended binary silently skips ja/ko/zh word segmentation and
# would reproduce the original bug for those locales.
#
# We deliberately do NOT use `mkdocs build --clean` for the hook path;
# if the caller forgot --clean, the pagefind step still runs and
# overwrites any stale pagefind/ in site/.

import logging
import shutil
import subprocess
import sys
from pathlib import Path

from mkdocs.plugins import event_priority

log = logging.getLogger("mkdocs.hooks.pagefind")


# mkdocs-static-i18n's on_post_build (priority -100 in that plugin) is
# the one that *triggers* the per-locale sub-builds: it sets
# `self.building = True`, then calls `mkdocs.commands.build.build(config)`
# once per non-current locale. Each sub-build recursively fires every
# `on_post_build` hook — so the i18n plugin and ours both run 6 times in
# total (1 outer + 5 sub-builds). The i18n plugin guards itself with
# `if self.building: return`; we use the same pattern via a module-level
# flag.
#
# We must run AFTER the i18n plugin so that, by the time we actually
# invoke pagefind, all 6 locale trees (site/ root, site/ko/, site/ja/,
# ...) are written to disk. mkdocs event priority: HIGHER number = called
# first. i18n is at -100; we use -200 to run strictly after it.
#
# Within those 6 hook invocations, the first 5 see site/ with a
# partial set of locale subdirectories. Only the last one (zh, the
# last locale alphabetically in the i18n plugin's build_languages list)
# sees all 6. We gate the pagefind run on "all 6 locale dirs present"
# so the heavy subprocess call only happens once, on the final call.
_BUILT_LOCALE_SUBDIRS: tuple[str, ...] = ("en", "ko", "es", "fr", "ja", "zh")
# Two pieces of state, both module-level, to guard against duplicate
# pagefind runs in a single mkdocs invocation:
#
#   _pagefind_in_progress (bool): reentrancy guard mirroring the i18n
#     plugin's `self.building`. Set when the subprocess is launched;
#     cleared on completion. A recursive on_post_build WHILE pagefind
#     is in flight would race against the first one and corrupt the
#     index files.
#
#   _processed_site_dirs (set[str]): "already done" set keyed by
#     absolute site_dir path. Once pagefind has finished for a given
#     site_dir in this mkdocs invocation, no further on_post_build
#     call for that site_dir will re-run it. This is the fix for the
#     trailing outer-build call: mkdocs fires on_post_build once per
#     sub-build (6 total) AND a final time for the outer build itself
#     AFTER the i18n plugin's on_post_build returns. Without this set,
#     that trailing call would re-launch pagefind once the reentrancy
#     flag has been cleared, producing two identical index passes.
_processed_site_dirs: set[str] = set()
_pagefind_in_progress: bool = False


@event_priority(-200)
def on_post_build(config, **kwargs) -> None:
    """Build the Pagefind search index into site/pagefind/.

    `config["site_dir"]` is the absolute path to the rendered site
    (typically `site/`). We invoke `pagefind` with `--site` pointing
    at that dir, which writes the per-locale shards into
    `<site_dir>/pagefind/`. The pagefind-component-ui.js script
    loaded by overrides/main.html reads from that path at runtime.

    This hook is called once per per-locale sub-build (6 total when
    all locales are present) PLUS a final time for the outer build
    itself (mkdocs fires on_post_build again after the i18n plugin's
    own on_post_build returns). We run pagefind only on the last
    sub-build call, which we detect by checking that all 6 locale
    subdirectories exist under site/. The first 5 sub-build calls
    + the trailing outer call all early-out silently.
    """
    global _pagefind_in_progress
    site_dir = Path(config["site_dir"])
    # Resolve to an absolute, canonical key so a parallel mkdocs
    # invocation against a different site_dir doesn't poison this one,
    # and so the same site_dir seen via different relative paths
    # de-dupes correctly.
    site_dir_key = str(site_dir.resolve()) if site_dir.exists() else str(site_dir)

    # Short-circuit: pagefind already completed for this site_dir in
    # this mkdocs invocation. This is the load-bearing guard against
    # the trailing outer on_post_build call re-running pagefind after
    # the reentrancy flag has been cleared.
    if site_dir_key in _processed_site_dirs:
        return

    if not site_dir.is_dir():
        log.error(
            "site_dir %s does not exist; mkdocs build did not produce "
            "an output tree. Skipping pagefind.",
            site_dir,
        )
        return

    # Only act on the last sub-build. The i18n plugin loops over
    # non-current locales in its own on_post_build and recursively
    # fires ours; we wait until all locale subdirs are present so
    # pagefind indexes the full site in a single pass.
    #
    # The default locale (en) is special: the i18n plugin does NOT
    # create site/en/ — its pages live directly under site/ (the
    # mkdocs root). The non-default locales each get their own
    # subdir. So "all locales present" means: site/index.html for
    # the default locale, and site/<loc>/index.html for the rest.
    default_locale = _BUILT_LOCALE_SUBDIRS[0]  # "en"
    if not (site_dir / "index.html").is_file():
        # Not even the default locale is on disk yet. Skip.
        return
    missing = [loc for loc in _BUILT_LOCALE_SUBDIRS[1:]
               if not (site_dir / loc / "index.html").is_file()]
    if missing:
        # Intermediate sub-build: skip silently. The final call will
        # see missing == [] and proceed.
        return

    # Reentrancy guard. A re-entrant call WHILE pagefind is still
    # in flight (shouldn't happen, but the i18n plugin has the same
    # guard so it's worth mirroring) would otherwise launch a
    # second pagefind subprocess against the same site_dir while
    # the first is still writing the index files.
    if _pagefind_in_progress:
        return
    _pagefind_in_progress = True
    try:
        _run_pagefind(site_dir, config)
        # Mark this site_dir as fully processed BEFORE clearing the
        # reentrancy flag, so the trailing outer call (which will hit
        # this hook after the reentrancy flag is False) finds the
        # site_dir in _processed_site_dirs and early-returns at the
        # top of the function.
        _processed_site_dirs.add(site_dir_key)
    finally:
        _pagefind_in_progress = False


def _run_pagefind(site_dir: Path, config) -> None:
    """Shell out to the extended pagefind binary, log its output, then
    run the per-locale shard TDD gate. Extracted so on_post_build can
    keep the reentrancy guard + last-call gate separate from the
    subprocess plumbing."""
    # Skip pagefind if `uvx` is not on PATH. The hook must be
    # non-fatal: the search bar will be missing, but the rest of the
    # site (and the gh-pages push) will still succeed. This keeps
    # local `mkdocs serve` usable on a machine that lacks uv.
    uvx = shutil.which("uvx")
    if uvx is None:
        log.warning(
            "uvx not on PATH; skipping pagefind build. The site will "
            "ship without search. Install uv from https://astral.sh/uv "
            "to enable search."
        )
        return

    log.info("Building Pagefind search index into %s/pagefind/", site_dir)
    result = subprocess.run(
        [
            uvx,
            "--from",
            "pagefind[extended]",
            "python",
            "-m",
            "pagefind",
            "--site",
            str(site_dir),
            "--output-subdir",
            "pagefind",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        log.error("pagefind failed (exit %d):\nstdout:\n%s\nstderr:\n%s",
                  result.returncode, result.stdout, result.stderr)
        # Non-fatal: we don't want a missing search bar to block the
        # rest of the deploy. The user will see a search button that
        # does nothing, which is a clearer failure than a dead CI run.
        return

    # Pipe pagefind's own output to mkdocs's logger so it shows up
    # in the build log alongside the "Documentation built in" line.
    #
    # Note: pagefind's returncode is 0 here (the `if` above would have
    # returned on a non-zero exit). Any remaining stderr lines from a
    # successful run are informational, not errors — typically the
    # per-locale "Search will still work, but will not match across
    # root words." notice for languages that don't have a stemmer
    # (the CJK ones). Logging those as `warning` would abort a
    # `mkdocs build --strict` run with "Aborted with N warnings" —
    # so we down-classify them to INFO. The TDD gate below
    # (`_verify_per_locale_shards`) is the real fail-fast for index
    # quality.
    for line in result.stdout.splitlines():
        if line.strip():
            log.info("pagefind: %s", line)
    for line in result.stderr.splitlines():
        if not line.strip():
            continue
        if "Pagefind" in line or "stemming" in line:
            continue
        if "Search will still work" in line or "root words" in line:
            # pagefind's per-locale CJK stemming notice. Informational;
            # log at INFO so `--strict` builds don't fail on it.
            log.info("pagefind: %s", line)
            continue
        log.warning("pagefind: %s", line)

    # Run the per-locale TDD gate. Same check as scripts/check_search_index.py
    # — we don't import that module because mkdocs's hook context
    # has no `__file__`-anchored REPO_ROOT we can rely on. Instead we
    # derive the check from config (mkdocs.yml is the source of truth
    # for the locale list).
    _verify_per_locale_shards(site_dir, config)


def _verify_per_locale_shards(site_dir: Path, config) -> None:
    """TDD gate: assert site/pagefind/ has one shard per build locale.
    Mirrors the assertion in scripts/check_search_index.py so the
    hook fails fast at build time if pagefind silently drops a
    locale (e.g., a non-extended binary on CJK content)."""
    import json
    entry_json = site_dir / "pagefind" / "pagefind-entry.json"
    if not entry_json.is_file():
        log.error(
            "pagefind-entry.json missing under %s — pagefind did not "
            "produce an entry manifest. Search will not work for any "
            "locale.", site_dir,
        )
        return
    data = json.loads(entry_json.read_text(encoding="utf-8"))
    languages = data.get("languages", {})
    # Read build locales from mkdocs.yml (the i18n plugin config).
    build_langs = [
        lang["locale"]
        for lang in config["plugins"]["i18n"].config["languages"]
        if lang.get("build", True)
    ]
    missing = [lang for lang in build_langs if lang not in languages]
    if missing:
        log.error(
            "pagefind missing shards for locales: %s "
            "(built but not indexed: %s). Check that the [extended] "
            "pagefind binary is being used (the non-extended one "
            "silently skips CJK).",
            missing, missing,
        )
        return
    log.info("Pagefind shards OK: %s", sorted(languages.keys()))
