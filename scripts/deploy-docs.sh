#!/bin/bash
# scripts/deploy-docs.sh
# Build the docs/ site and push it to the gh-pages branch.
#
# Usage:
#   ./scripts/deploy-docs.sh           # build, preview locally, then deploy
#   ./scripts/deploy-docs.sh -y        # skip the preview prompt
#   ./scripts/deploy-docs.sh --no-preview   # same as -y
#
# This is the single source of truth for docs deploys. After editing anything
# under docs/ or mkdocs.yml, run this from the repo root.

set -euo pipefail

# Run from the repo root so paths in mkdocs.yml resolve correctly.
cd "$(dirname "$0")/.."

# -- Bootstrap mkdocs via uvx ------------------------------------------------
# We don't assume a globally-installed mkdocs. uv is already required by the
# Nimbus install script, so it's available everywhere this script runs. uvx
# pulls mkdocs + mkdocs-material into an ephemeral env on first run and
# caches it for subsequent invocations.
#
# --with mkdocs-static-i18n is required for the per-locale docs/ directory
# layout (docs/en/, docs/ko/, ...). The plugin is third-party (not bundled
# with mkdocs-material), so we layer it into the same uvx env. If you forget
# this, mkdocs builds only the en/ tree and silently drops the other locales.
MKDOCS=(uvx --from mkdocs-material --with mkdocs-material[imaging] --with mkdocs-static-i18n mkdocs)
if ! command -v uv >/dev/null 2>&1; then
    echo "uv is required to run this script. Install it from https://astral.sh/uv" >&2
    exit 1
fi

# -- Dirty working tree guard -----------------------------------------------
# mkdocs gh-deploy ships any uncommitted files along with site/. Refuse
# up front rather than push a half-built site by accident.
if ! git diff --quiet HEAD 2>/dev/null || [ -n "$(git status --porcelain)" ]; then
    echo "Working tree is dirty. Commit or stash your changes before deploying." >&2
    git status --short >&2
    exit 1
fi

# -- Build (strict) ---------------------------------------------------------
# --strict turns warnings (broken links, missing pages, etc.) into errors.
# Cheap insurance: catching typos at build time beats catching them in prod.
echo "→ Building site (strict)..."
"${MKDOCS[@]}" build --strict --clean

# -- Pagefind search index --------------------------------------------------
# mkdocs-material's built-in search plugin is intentionally omitted from
# mkdocs.yml — it produces a single shared lunr multiLanguage index whose
# union of stemmers is broken for CJK (lunr-languages#45, open since 2022;
# the upstream fix in lunr-languages 1.15.0 has not reached mkdocs-material's
# bundled lunr copy as of 2026-07). On /ko/ that index returns English
# results because the multiLanguage tokenizer can't segment Korean and
# 78 English docs dominate scoring against 31 Korean docs.
#
# Pagefind reads <html lang="..."> at index time and at search time, and
# ships one .pf_index shard per locale. /ko/ search input → ko shard only,
# with proper Korean (bigram) segmentation.
#
# The [extended] extra pulls the pagefind_extended binary; the non-extended
# binary silently skips word segmentation for ja/ko/zh, which would
# reproduce the original bug for those locales.
#
# HOW/WHERE pagefind runs: it is invoked by the mkdocs hook at
# scripts/pagefind_hook.py, registered in mkdocs.yml's `hooks:` block.
# The hook fires on `on_post_build` so the per-locale shards land in
# site/pagefind/ INSIDE the mkdocs build itself — which is required
# because `mkdocs gh-deploy` always runs its own `mkdocs build` before
# pushing, and any site/ we pagefind from a prior step is wiped by
# that embedded build. Running pagefind from THIS shell script would
# therefore produce a perfectly indexed site/ that is then overwritten
# with an empty one by gh-deploy. The hook is the load-bearing path.

# -- TDD guard --------------------------------------------------------------
# Run the per-locale pagefind shard gate before the human preview. If
# pagefind didn't produce one shard per locale (e.g., the CJK binary
# wasn't extended, or pagefind ran on an empty site/), fail fast here
# rather than ship a search bar that returns nothing on /ko/.
echo "→ Verifying per-locale search index..."
python3 scripts/check_search_index.py

# -- Preview gate -----------------------------------------------------------
# mkdocs gh-deploy has no built-in review step — once it runs, the change is
# on the public site. The mkdocs docs explicitly warn about this. Open the
# local server, let a human eyeball the result, then continue.
PREVIEW=1
case "${1:-}" in
    -y|--no-preview) PREVIEW=0 ;;
esac

if [ "$PREVIEW" = 1 ] && [ -t 0 ]; then
    echo "→ Preview at http://127.0.0.1:8000 (Ctrl-C to abort, Enter to deploy)"
    (cd site && python3 -m http.server 8000 >/dev/null 2>&1) &
    SERVER_PID=$!
    cleanup() { kill "$SERVER_PID" 2>/dev/null || true; }
    trap cleanup EXIT INT TERM
    read -r _
    cleanup
    trap - EXIT INT TERM
fi

# -- Deploy -----------------------------------------------------------------
# --force: gh-pages is a build artifact branch that always "diverges" from
# main. Without --force, gh-deploy refuses to push. --ignore-version lets
# us deploy even if the local mkdocs is older than the last deploy (the
# cached env will refresh as needed).
SHA=$(git rev-parse --short HEAD)
echo "→ Deploying $SHA to gh-pages..."
"${MKDOCS[@]}" gh-deploy \
    --force \
    --ignore-version \
    --message "Deployed $SHA with MkDocs {version}"
