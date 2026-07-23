#!/usr/bin/env python3
# scripts/check_translations.py
#
# TDD guard for Phase 7b: asserts every non-legal page in docs/en/ has a
# non-empty, non-stub translation in each docs/<locale>/ tree, and that
# the legal pages (license, terms_of_service, privacy_policy) are NOT
# translated (they ship English-only with an authoritative-version notice).
#
# Invoked as a script: exits 0 on pass, non-zero on first failure.
# Invoked via `python3 -m unittest`: each locale is a separate test method
# so per-locale TDD is observable from CI output.
#
# Locale list MUST match the `languages:` block in mkdocs.yml (and, in the
# other repos, nimbus-cli/src/locale.rs and dashboard/src/lib/const.ts).
# When adding a locale, add it everywhere.

from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_DIR = REPO_ROOT / "docs"

# Mirror of mkdocs.yml `plugins.i18n.languages[].locale` (non-default only).
# `en` is the source of truth and is not checked against itself.
LOCALES: tuple[str, ...] = ("ko", "es", "fr", "ja", "zh")

# Pages we ship English-only. The non-en trees must NOT contain a
# translation of these (the en/ copy carries the authoritative-version
# notice and is the only version we publish). A non-en file with one of
# these names means someone translated it by mistake; fail loudly.
LEGAL_FILES: frozenset[str] = frozenset({
    "license.md",
    "terms_of_service.md",
    "privacy_policy.md",
})

# Marker that a stub translator might leave behind. Any file containing
# this exact string is treated as not-translated, even if it has bytes.
TRANSLATION_STUB_MARKER: str = "TODO: translate"


def _en_basenames() -> list[str]:
    """Sorted .md filenames in docs/en/ (the source-of-truth tree)."""
    en_dir = DOCS_DIR / "en"
    if not en_dir.is_dir():
        return []
    return sorted(p.name for p in en_dir.glob("*.md"))


def _locale_dir(locale: str) -> Path:
    return DOCS_DIR / locale


def _check_locale(locale: str) -> list[str]:
    """Return a list of human-readable failure messages for `locale`.

    Empty list means the locale tree is complete: every product page in
    docs/en/ has a non-empty, non-stub counterpart, and no legal page
    has been translated by mistake.
    """
    failures: list[str] = []
    locale_dir = _locale_dir(locale)

    if not locale_dir.is_dir():
        failures.append(
            f"docs/{locale}/ is missing entirely "
            f"(expected a per-locale tree mirroring docs/en/)"
        )
        return failures

    for basename in _en_basenames():
        candidate = locale_dir / basename
        if basename in LEGAL_FILES:
            # Legal pages must NOT be in non-en trees.
            if candidate.exists():
                failures.append(
                    f"docs/{locale}/{basename} exists but should be English-only "
                    f"(legal text is authoritative in English; see the "
                    f"authoritative-version notice in docs/en/{basename})"
                )
            continue

        # Product page: must exist, be non-empty, and have no stub marker.
        if not candidate.exists():
            failures.append(
                f"docs/{locale}/{basename} is missing "
                f"(docs/en/{basename} exists and should be translated)"
            )
            continue
        content = candidate.read_text(encoding="utf-8")
        stripped = content.strip()
        if not stripped:
            failures.append(
                f"docs/{locale}/{basename} is empty "
                f"(docs/en/{basename} needs a translation here)"
            )
            continue
        if TRANSLATION_STUB_MARKER in content:
            failures.append(
                f"docs/{locale}/{basename} contains the stub marker "
                f"'{TRANSLATION_STUB_MARKER}' — replace the stub with a "
                f"real translation"
            )
            continue

    return failures


class TranslationParityTests(unittest.TestCase):
    """One test method per non-en locale. Each commits-and-runs CI makes
    its locale green; the others stay red until their commits land.

    Per-method isolation means a single failing locale does not mask the
    others in the CI log — you can read off "ko green, es green, fr red,
    ja red, zh red" directly from the test output."""

    def _assert_locale_clean(self, locale: str) -> None:
        failures = _check_locale(locale)
        if failures:
            self.fail(
                f"Translation parity failed for locale '{locale}':\n  - "
                + "\n  - ".join(failures)
            )

    def test_ko_has_all_product_pages(self) -> None:
        self._assert_locale_clean("ko")

    def test_es_has_all_product_pages(self) -> None:
        self._assert_locale_clean("es")

    def test_fr_has_all_product_pages(self) -> None:
        self._assert_locale_clean("fr")

    def test_ja_has_all_product_pages(self) -> None:
        self._assert_locale_clean("ja")

    def test_zh_has_all_product_pages(self) -> None:
        self._assert_locale_clean("zh")

    def test_en_tree_is_source_of_truth(self) -> None:
        """The en/ tree must contain every page referenced by mkdocs.yml
        nav, and it must never be empty (we'd be shipping no English)."""
        en_dir = DOCS_DIR / "en"
        self.assertTrue(
            en_dir.is_dir(),
            "docs/en/ is missing — the i18n plugin requires a default locale",
        )
        basenames = set(_en_basenames())
        # Every non-legal product page must be present in en/.
        for legal in LEGAL_FILES:
            self.assertIn(
                legal, basenames,
                f"docs/en/{legal} is missing — the en/ tree is incomplete",
            )
        self.assertIn(
            "index.md", basenames,
            "docs/en/index.md is missing — the home page is required",
        )


if __name__ == "__main__":
    # When invoked as a script, run all tests and exit non-zero on failure.
    # `--locale <code>` filters to a single locale for fast local TDD.
    if "--locale" in sys.argv:
        idx = sys.argv.index("--locale")
        try:
            only = sys.argv[idx + 1]
        except IndexError:
            print("error: --locale requires a value", file=sys.stderr)
            sys.exit(2)
        if only not in LOCALES:
            print(
                f"error: unknown locale '{only}' "
                f"(supported: {', '.join(LOCALES)})",
                file=sys.stderr,
            )
            sys.exit(2)
        failures = _check_locale(only)
        if failures:
            print(f"FAIL: locale '{only}' is not translation-complete:")
            for f in failures:
                print(f"  - {f}")
            sys.exit(1)
        print(f"OK: locale '{only}' has all product pages translated")
        sys.exit(0)

    # Default: run the full unittest suite. Capture result and exit
    # non-zero on failure so CI sees the right status code.
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(unittest.defaultTestLoader.loadTestsFromTestCase(TranslationParityTests))
    sys.exit(0 if result.wasSuccessful() else 1)
