#!/usr/bin/env python3
# scripts/check_search_index.py
#
# TDD guard for the per-locale search index: asserts that after
# `mkdocs build` + the pagefind post-build step, the site/ tree has
# per-locale Pagefind index shards. The header search bar in
# mkdocs-material loads `pagefind/pagefind-entry.json` at runtime, reads
# the current page's `<html lang="...">`, and pulls the matching locale
# shard. If the shards are missing or merged into one global index, the
# Korean user sees English results (because the shared index is
# dominated by 78 English docs vs 31 Korean).
#
# Surface this guards:
#   1. site/pagefind/pagefind-entry.json exists (Pagefind ran)
#   2. The entry JSON lists one shard per build language (en, ko, es, fr, ja, zh)
#   3. Each shard's .pf_index file actually exists in site/pagefind/index/
#   4. The current build language list (from mkdocs.yml) is a subset of
#      the languages Pagefind detected (catches a locale added in mkdocs.yml
#      but missing from the index because Pagefind wasn't re-run)
#   5. The .pf_index files for non-en locales are non-empty (catches a
#      silent re-run on an empty site/)
#
# Invoked as a script: exits 0 on pass, non-zero on first failure.
# Invoked via `python3 -m unittest`: each check is a separate test method
# so per-locale TDD is observable from CI output.
#
# Locale list MUST match the `languages:` block in mkdocs.yml (and, in the
# other repos, nimbus-cli/src/locale.rs and dashboard/src/lib/const.ts).
# When adding a locale, add it everywhere.

from __future__ import annotations

import json
import re
import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SITE_DIR = REPO_ROOT / "site"
PAGEFIND_DIR = SITE_DIR / "pagefind"
ENTRY_JSON = PAGEFIND_DIR / "pagefind-entry.json"
INDEX_DIR = PAGEFIND_DIR / "index"
MKDOCS_YML = REPO_ROOT / "mkdocs.yml"

# Mirror of mkdocs.yml `plugins.i18n.languages[].locale`. The default
# locale (en) is included here because mkdocs builds it at site/ root
# and Pagefind indexes it under the "en" key.
LOCALES: tuple[str, ...] = ("en", "ko", "es", "fr", "ja", "zh")


def _read_build_languages_from_mkdocs_yml() -> list[str]:
    """Read the locale codes from mkdocs.yml's `plugins.i18n.languages`
    block. Used to assert that the Pagefind entry JSON covers every
    language mkdocs actually built.
    """
    if not MKDOCS_YML.is_file():
        return []
    text = MKDOCS_YML.read_text(encoding="utf-8")
    # Match `  - locale: <code>` inside the i18n languages block.
    # The block is well-formed YAML; a regex is fine here because the
    # format is stable and we want a fast, hermetic check that doesn't
    # require re-parsing the whole config.
    return re.findall(r"^\s*-\s+locale:\s+([a-z]{2})\s*$", text, re.MULTILINE)


class PagefindIndexTests(unittest.TestCase):
    """Per-locale TDD gate for the Pagefind search index.

    One test method per invariant. Failures name the missing/wrong
    piece directly so the fix is obvious."""

    def test_pagefind_directory_exists(self) -> None:
        """site/pagefind/ must exist after `mkdocs build` + the pagefind
        post-build step. If this fails, the pagefind command wasn't run
        in deploy-docs.sh (or `mkdocs build --clean` wiped it)."""
        self.assertTrue(
            PAGEFIND_DIR.is_dir(),
            f"{PAGEFIND_DIR.relative_to(REPO_ROOT)} is missing — "
            "pagefind was not run after mkdocs build. Add "
            "`uvx --from 'pagefind[extended]' python -m pagefind "
            "--site site --output-subdir pagefind` to deploy-docs.sh "
            "after the `mkdocs build` step.",
        )

    def test_pagefind_entry_json_exists_and_is_valid(self) -> None:
        """pagefind-entry.json is the manifest Pagefind's JS reads at
        runtime to discover per-locale shards. Must exist and parse."""
        self.assertTrue(
            ENTRY_JSON.is_file(),
            f"{ENTRY_JSON.relative_to(REPO_ROOT)} is missing — "
            "pagefind did not produce an entry manifest. The site "
            "build is incomplete.",
        )
        try:
            data = json.loads(ENTRY_JSON.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            self.fail(f"{ENTRY_JSON.relative_to(REPO_ROOT)} is not valid JSON: {e}")
        self.assertIn(
            "languages", data,
            f"{ENTRY_JSON.relative_to(REPO_ROOT)} has no 'languages' key — "
            "this is not a Pagefind 1.x manifest.",
        )

    def test_entry_lists_one_shard_per_mkdocs_locale(self) -> None:
        """Every locale mkdocs built must appear in pagefind-entry.json.
        If a locale is added to mkdocs.yml but Pagefind wasn't re-run
        (or it found no <html lang=...> pages for that locale), the
        header search bar will silently fall through to whatever's
        available — usually en."""
        if not ENTRY_JSON.is_file():
            self.skipTest(f"{ENTRY_JSON.relative_to(REPO_ROOT)} missing (covered by other tests)")
        data = json.loads(ENTRY_JSON.read_text(encoding="utf-8"))
        languages: dict = data.get("languages", {})
        # Prefer the live mkdocs.yml as the source of truth; fall back
        # to the hard-coded list if the file isn't readable.
        build_langs = _read_build_languages_from_mkdocs_yml() or list(LOCALES)
        for locale in build_langs:
            self.assertIn(
                locale, languages,
                f"pagefind-entry.json has no shard for locale '{locale}' "
                f"(mkdocs.yml builds it; available: {sorted(languages)}). "
                f"Re-run pagefind on a fresh build, or check that the "
                f"locale's pages carry <html lang=\"{locale}\">.",
            )

    def test_each_locale_has_a_pf_index_file(self) -> None:
        """Every locale in the entry JSON must have at least one
        .pf_index shard on disk under site/pagefind/index/. The entry
        JSON's `hash` field is the runtime URL the header bar requests
        (Pagefind looks up the file by `<lang>_<hash>.pf_index`); if
        the file is missing, the search returns 0 results.

        NOTE: pagefind-entry.json stores the hash with a longer prefix
        (10 hex chars after `<lang>_`) than the on-disk filename (7
        hex chars). We don't try to match them by string equality —
        instead we glob for `<lang>_*.pf_index` and assert at least
        one shard exists per locale, which is the load-bearing
        invariant the runtime actually depends on."""
        if not ENTRY_JSON.is_file():
            self.skipTest(f"{ENTRY_JSON.relative_to(REPO_ROOT)} missing (covered by other tests)")
        data = json.loads(ENTRY_JSON.read_text(encoding="utf-8"))
        languages: dict = data.get("languages", {})
        if not INDEX_DIR.is_dir():
            self.fail(
                f"{INDEX_DIR.relative_to(REPO_ROOT)} is missing — "
                "pagefind did not write per-locale index files. The "
                "search will not work for any locale."
            )
        for locale in languages:
            shards = sorted(INDEX_DIR.glob(f"{locale}_*.pf_index"))
            self.assertTrue(
                shards,
                f"pagefind entry lists locale '{locale}' but no "
                f"{INDEX_DIR.relative_to(REPO_ROOT)}/{locale}_*.pf_index "
                f"shard exists on disk. Re-run pagefind.",
            )

    def test_no_pf_index_file_is_empty(self) -> None:
        """An empty .pf_index means pagefind ran on a wiped site/ —
        the search would return zero results in that locale."""
        if not INDEX_DIR.is_dir():
            self.skipTest(f"{INDEX_DIR.relative_to(REPO_ROOT)} missing (covered by other tests)")
        empty_shards = [p.name for p in INDEX_DIR.glob("*.pf_index") if p.stat().st_size == 0]
        self.assertEqual(
            empty_shards, [],
            f"empty pagefind shards: {empty_shards}. Re-run pagefind "
            f"against a populated site/ (the build may have been wiped).",
        )

    def test_cjk_locales_are_indexed(self) -> None:
        """The CJK locales (ja, ko, zh) must have shards. Without them,
        those users get either 0 results or English-only results from
        the en shard — the original bug we're fixing."""
        if not ENTRY_JSON.is_file():
            self.skipTest(f"{ENTRY_JSON.relative_to(REPO_ROOT)} missing (covered by other tests)")
        data = json.loads(ENTRY_JSON.read_text(encoding="utf-8"))
        languages: dict = data.get("languages", {})
        for cjk in ("ja", "ko", "zh"):
            self.assertIn(
                cjk, languages,
                f"pagefind-entry.json has no shard for CJK locale '{cjk}' "
                f"(available: {sorted(languages)}). CJK pages exist in "
                f"docs/{cjk}/ but are not being indexed. The pagefind "
                f"binary used must be the *extended* one (`uvx --from "
                f"'pagefind[extended]' python -m pagefind ...`); the "
                f"non-extended binary silently skips CJK.",
            )


if __name__ == "__main__":
    # When invoked as a script, run all tests and exit non-zero on failure.
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(
        unittest.defaultTestLoader.loadTestsFromTestCase(PagefindIndexTests)
    )
    sys.exit(0 if result.wasSuccessful() else 1)
