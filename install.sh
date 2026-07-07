#!/bin/bash
# Nimbus Installer - Premium Edition
# Usage: curl -fsSL https://nimbus.yoodule.com/install.sh | bash
#   Pin a version:  NIMBUS_VERSION=vX.Y.Z bash  (i.e. before the `bash` at the end of the pipe)

set -e

REPO="Yoodule/nimbus"
INSTALL_DIR="${NIMBUS_HOME:-$HOME/.nimbus}"

# --- Aesthetics (Yoodule Style: High Contrast, Minimalist) ---
BOLD='\033[1m'
BLUE='\033[34m'
CYAN='\033[36m'
YELLOW='\033[33m'
NC='\033[0m'

clear
echo ""
# Print the Nimbus brand mark as a **pre-baked stacked layout**:
# 26-line block-shading icon on top, 1 blank separator, 3-line
# text-block (wordmark / value prop / URL) centered within the
# 65-cell icon width, divider beneath — 31 rows total. Pre-baked
# by `nimbus-cli/build.rs` (writes `logo.banner`, copied to
# `release/banner.txt` by `scripts/release.sh`) and inlined into
# the heredoc below at release-build time (see the heredoc
# comment for the placeholder name). The runtime CLI's `print_banner`
# uses `banner::build_banner_lines` instead so it can pick layout by
# terminal width; the install banner is the brand's "best foot
# forward" — 65 cells, fixed, always renders the same shape.
#
# TTY gating: if the installer is being piped into another
# program (e.g. `curl -fsSL install.sh | bash > /tmp/log`), skip
# the banner entirely — block-shading characters in a log file
# are noise.
#
# The heredoc's closing `BANNER_EOF` is at column 0 by design —
# bash requires that for `<<'EOF'` (vs. `<<-EOF`, which only
# strips leading TABS, not spaces). The 2-space indent on each
# body line is baked into the file by build.rs (writes
# `logo.banner`) so the icon column-aligns with the
# 2-space-indented install text below (`  Preparing your
# environment...`).
if [ -t 1 ]; then
    cat <<'BANNER_EOF'
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████▒░▓█████████████████████████████████████████
  █████████████████████  ░███████████████████▓ ░███████████████████
  ████████████████▒░░░     ░░░▓███████████▓░░    ░▒████████████████
  ████████████████▓▓▒░     ░▒▓██████▓▓█████▓▒   ▒▓▓████████████████
  █████████████████████  ░█████████   ███████▓░▒███████████████████
  █████████████████████▒░▓████████▒   ▒████████████████████████████
  ███████████████████████████████░     ░███████████████████████████
  ███████████████████████████▓▒           ▒▓███████████████████████
  ██████████████████████░                       ░██████████████████
  █████████████████████████▓▒░             ░▒▓█████████████████████
  ██████████████████████████████▒       ▒██████████████████████████
  ████████████████████████████████░   ▒████████████████████████████
  █████████████████████████████████   █████████████████████████████
  █████████████████████████████████▓░▒█████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
                                                                   
                     NIMBUS — Your 24/7 Employee
   One command. No sign-up. The unified semantic gateway for MCP.
                     https://nimbus.yoodule.com
  ─────────────────────────────────────────────────────────────────
BANNER_EOF
fi
echo ""
echo -e "  Preparing your environment..."

# 1. System Check
printf "  Detecting system... "
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
[ "$ARCH" = "x86_64" ] && ARCH="amd64"
[[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]] && ARCH="arm64"
echo -e "${BLUE}Done ($OS-$ARCH)${NC}"

# 1.1 Export NIMBUS_HOST_ARCH so the compose file can pick the right
# platform variant from multi-arch images. Override with NIMBUS_HOST_ARCH
# in the env (e.g. `NIMBUS_HOST_ARCH=linux/amd64 bash …`) to force a
# different arch — useful on Apple Silicon under Rosetta or in CI.
export NIMBUS_HOST_ARCH="linux/$ARCH"

# 1.5 Ensure uv is installed (required for running MCP servers)
if ! command -v uv >/dev/null 2>&1; then
    printf "  uv not found. Installing uv... "
    if curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1; then
        export PATH="$HOME/.local/bin:$PATH"
        echo -e "${BLUE}Done${NC}"
    else
        echo -e "${RED}Failed. Please install manually: https://astral.sh/uv${NC}"
    fi
fi

# 2. Local-repo guard. The dev branch used to live here — building
# cargo + rsyncing source into $INSTALL_DIR — but that path is for
# maintainers and contributors only, never for `curl | bash`. If we
# detect a local clone, refuse to run and tell the user which script
# to use instead. A failure here is the correct outcome: a maintainer
# running install.sh by accident should be redirected to the right
# tool, not silently get a half-broken install.
if [[ -f "nimbus-cli/Cargo.toml" && -d "src" ]]; then
    echo ""
    echo -e "  ${BOLD}Local repository detected.${NC} This script downloads a prebuilt"
    echo "  release from GitHub. To install from a local clone, run:"
    echo ""
    echo -e "    ${BOLD}./scripts/dev-install.sh${NC}"
    echo ""
    exit 1
fi

# 3. Fetching Release
printf "  Fetching latest release... "
    # Resolve version when NIMBUS_VERSION is unset. /releases/latest returns
    # the newest non-draft, non-prerelease release. If you need a specific
    # build (including prereleases), set NIMBUS_VERSION explicitly.
    if [ -z "${NIMBUS_VERSION:-}" ]; then
        # Hit the GitHub API for the most recent non-prerelease tag. The
        # fallback below is a frozen-in-time version used only when the API
        # is unreachable (offline install, rate limit, etc.).
        RESOLVED=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
            2>/dev/null | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
        if [ -n "$RESOLVED" ]; then
            NIMBUS_VERSION="$RESOLVED"
        else
            # Frozen-in-time fallback used only when the API is unreachable
            # (offline install, rate limit, etc.). Update when cutting releases.
            NIMBUS_VERSION="v1.0.12"
        fi
    fi
    if [ -z "$NIMBUS_VERSION" ]; then
        echo -e "\n  ${BOLD}Error:${NC} Could not resolve a release version. Set NIMBUS_VERSION=vX.Y.Z and retry."
        exit 1
    fi

    RELEASE_BASE="https://github.com/$REPO/releases/download/$NIMBUS_VERSION"
    RELEASE_URL="${RELEASE_BASE}/nimbus-$OS-$ARCH.tar.gz"

    # Ensure the install dir exists before any download/extract, so a fresh
    # user (no ~/.nimbus yet) doesn't fail on the first tar.
    mkdir -p "$INSTALL_DIR"

    # Probe the asset. -L follows GitHub's redirect to the S3-backed CDN,
    # so we get the real 200/404 instead of the 302 that GitHub returns at
    # the origin. Without -L, the arm64 probe would always look "missing"
    # and the script would fall through to a nonexistent amd64 asset.
    ASSET_STATUS=$(curl -fsSLI -o /dev/null -w '%{http_code}' "$RELEASE_URL" || echo "000")
    if [ "$ASSET_STATUS" != "200" ] && [ "$OS" = "darwin" ] && [ "$ARCH" = "arm64" ]; then
        # Apple Silicon under Rosetta can run the Intel binary, but we don't
        # currently ship one. Fail fast with the actionable URL rather than
        # burning another 404 on an asset that doesn't exist.
        echo ""
        echo -e "  ${BOLD}Error:${NC} No darwin-arm64 asset found for $NIMBUS_VERSION."
        echo "  Check available assets at: $RELEASE_BASE"
        echo "  To install via Rosetta instead, set NIMBUS_HOST_ARCH=amd64."
        exit 1
    fi

    ASSET_NAME=$(basename "$RELEASE_URL")
    echo -e "${BLUE}$NIMBUS_VERSION${NC}"

    # 3. Downloading + verifying
    echo -e "  Downloading assets..."
    TMP_DIR=$(mktemp -d)
    TMP_FILE="$TMP_DIR/$ASSET_NAME"
    trap 'rm -rf "$TMP_DIR"' EXIT

    if ! curl -# -fSL "$RELEASE_URL" -o "$TMP_FILE"; then
        echo -e "\n  ${BOLD}Error:${NC} Download failed ($RELEASE_URL)."
        exit 1
    fi

    # Verify SHA256 against the release's SHA256SUMS. We download the sidecar
    # over the same pinned release tag so the checksum and the asset move
    # together. The grep is positional — SHA256SUMS lines look like
    # "<hex>  <asset-name>".
    SHA256SUMS_URL="${RELEASE_BASE}/SHA256SUMS"
    if curl -fsSL "$SHA256SUMS_URL" -o "$TMP_DIR/SHA256SUMS" \
        && grep -E "^[0-9a-f]{64}  ${ASSET_NAME}\$" "$TMP_DIR/SHA256SUMS" \
            | (cd "$TMP_DIR" && sha256sum -c --strict -); then
        printf "  Checksum verified... ${BLUE}OK${NC}\n"
    else
        echo -e "\n  ${BOLD}Error:${NC} SHA256 verification failed for $ASSET_NAME."
        echo "  Refusing to install. Verify the release at $RELEASE_BASE manually."
        exit 1
    fi

    # Verify the release's signed manifest with minisign. SHA256 above
    # protects the archive against tampering by anyone with write
    # access to the GitHub Release; minisign on manifest.json proves
    # the manifest was published by a holder of the Yoodule signing key
    # (separate from the GitHub account — even a compromised GH token
    # can't mint a valid manifest without the minisign secret). Both
    # checks are required: SHA256 is the "this asset is what I asked
    # for" check, minisign is the "this is actually from Yoodule"
    # check.
    #
    # Key custody: nimbus-cli/minisign.pub in the repo. It MUST be
    # reviewed at every release (key rotation is a manual op). Same
    # key is embedded into the Rust CLI at compile time so the
    # `nimbus update` and `nimbus doctor` commands trust the same anchor.
    if ! command -v minisign >/dev/null 2>&1; then
        printf "  minisign not found. Installing... "
        if command -v brew >/dev/null 2>&1; then
            brew install minisign >/dev/null 2>&1 && echo -e "${BLUE}Done${NC}" || \
                { echo -e "${RED}Failed. Run: brew install minisign${NC}"; exit 1; }
        elif command -v apt-get >/dev/null 2>&1; then
            apt-get install -y minisign >/dev/null 2>&1 && echo -e "${BLUE}Done${NC}" || \
                { echo -e "${RED}Failed. Run: sudo apt-get install -y minisign${NC}"; exit 1; }
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y minisign >/dev/null 2>&1 && echo -e "${BLUE}Done${NC}" || \
                { echo -e "${RED}Failed. Run: sudo dnf install -y minisign${NC}"; exit 1; }
        else
            echo -e "${RED}Failed. Install minisign from https://jedisct1.github.io/minisign/ and retry.${NC}"
            exit 1
        fi
    fi
    MINISIGN_PUB_URL="${RELEASE_BASE}/minisign.pub"
    if ! curl -fsSL "$MINISIGN_PUB_URL" -o "$TMP_DIR/minisign.pub"; then
        echo -e "\n  ${BOLD}Error:${NC} Failed to download minisign.pub from $MINISIGN_PUB_URL."
        exit 1
    fi
    # Pin the pubkey against an embedded fingerprint baked into this
    # installer. The downloaded pubkey from the release is what we
    # actually use to verify the manifest, but we compare its key ID
    # to a known constant before trusting it. Without this pin, a
    # release that swaps the pubkey would go unchallenged.
    #
    # To rotate the key:
    #   1. Generate a new keypair (minisign -G -p new.pub -W)
    #   2. Replace nimbus-cli/minisign.pub with new.pub
    #   3. Re-embed the new key ID in EMBEDDED_PUBKEY_FINGERPRINT here
    #   4. Re-deploy install.sh
    #   5. Burn the old secret key (rm ~/.minisign/nimbus.key)
    #
    # Key ID is the first 8 bytes of the second base64 line of the
    # minisign pub file, hex-encoded. To extract from a fresh
    # minisign -G -p foo.pub: `tail -1 foo.pub | base64 -d | xxd -p -l 8`.
    EMBEDDED_PUBKEY_FINGERPRINT="4564ce7ac278e3f4"
    KEY_ID=$(tail -1 "$TMP_DIR/minisign.pub" | base64 -d 2>/dev/null | xxd -p -l 8 2>/dev/null || echo "UNKNOWN")
    if [ "$EMBEDDED_PUBKEY_FINGERPRINT" = "REPLACE_ME_AT_KEY_GENERATION_TIME" ]; then
        printf "  ${YELLOW}minisign pubkey not pinned in installer — key rotation is unverified.${NC}\n"
    elif [ "$KEY_ID" != "$EMBEDDED_PUBKEY_FINGERPRINT" ]; then
        echo ""
        echo -e "  ${RED}${BOLD}SECURITY: minisign.pub key ID mismatch.${NC}"
        echo "  Expected: $EMBEDDED_PUBKEY_FINGERPRINT"
        echo "  Got:      $KEY_ID"
        echo "  This may indicate a key rotation, a release artifact tampering,"
        echo "  or an installer that's out of date. Refusing to proceed."
        echo "  See: $MINISIGN_PUB_URL"
        exit 1
    fi
    if curl -fsSL "${RELEASE_BASE}/manifest.json" -o "$TMP_DIR/manifest.json" \
        && curl -fsSL "${RELEASE_BASE}/manifest.json.minisig" -o "$TMP_DIR/manifest.json.minisig" \
        && (cd "$TMP_DIR" && minisign -V -p minisign.pub -m manifest.json -q); then
        printf "  Signature verified... ${BLUE}OK${NC}\n"
    else
        echo -e "\n  ${BOLD}Error:${NC} Manifest signature verification failed."
        echo "  Refusing to install. The release at $RELEASE_BASE may be"
        echo "  tampered with, or your clock is significantly off."
        exit 1
    fi

    # 4. Extracting
    printf "  Installing Nimbus... "
    if ! tar -xzf "$TMP_FILE" -C "$INSTALL_DIR"; then
        echo -e "\n  ${BOLD}Error:${NC} Extraction failed."
        exit 1
    fi
    rm -rf "$TMP_DIR"
    echo -e "${BLUE}Success${NC}"

    BINARY_NAME="nimbus-$OS-$ARCH"
    [ ! -f "$INSTALL_DIR/$BINARY_NAME" ] && BINARY_NAME="nimbus"

    # 4.5 First-run .env stub. The runtime reads every env var from
    # $NIMBUS_HOME/.env (gateway via load_env_file in nimbus-cli/src/main.rs,
    # dashboard via compose env propagation in compose_up.rs:run_compose).
    # Without this file, `nimbus start` crashes on the first env lookup it
    # can't synthesize. Generate a stub with the same 27 keys as the
    # shipped working env so the install "just works" — user pastes real
    # values into the empty fields on first start. Skip silently if the
    # file already exists (dev re-installs, existing users).
    #
    # We do NOT generate real values for any secret. Only structural
    # defaults (GATEWAY_PORT, QDRANT_URL, EMBEDDING_MODEL, NIMBUS_DOMAIN,
    # NIMBUS_GATEWAY_URL) get non-empty values — the rest are empty
    # placeholders. Per feedback-no-real-domains-in-dev.md, NIMBUS_DOMAIN
    # defaults to localhost (not the production hostname) so a fresh
    # install is self-evidently local; production deploys override
    # directly. The file is chmod'd 0600 because it WILL hold real
    # secrets once the user populates it — same pattern as
    # project-cli-config-file.md (config file is 0600).
    if [ ! -f "$INSTALL_DIR/.env" ]; then
        cat > "$INSTALL_DIR/.env" <<'NIMBUS_ENV_EOF'
# Nimbus runtime config — generated by install.sh on first install.
# Paste your real values into the empty fields, then run `nimbus start`.
# See https://nimbus.yoodule.com for the full list of integrations.

# --- Secrets (paste your real values) ---
UPWORK_REDIRECT_URI=
UPWORK_CLIENT_ID=
NIMBUS_APPROVED=
EXA_API_KEY=
POLYGON_RPC_URL=
NIMBUS_USER_EMAIL=
NIMBUS_USER_NAME=
NIMBUS_API_KEY=
GITHUB_TOKEN=
CLOUDFLARE_API_TOKEN=
CLOUDFLARE_ZONE_ID=
BETTER_AUTH_SECRET=
QDRANT_API_KEY=
NIMBUS_ADMIN_PASSWORD=
POLYMARKET_PRIVATE_KEY=
NIMBUS_RUN_MODE=
UPWORK_API_KEY_NAME=
UPWORK_ACCOUNT_TYPE=
UPWORK_CLIENT_SECRET=
NIMBUS_OPENROUTER_KEY=
UPWORK_PERMISSIONS=
OPENROUTER_API_KEY=
MINISIGN_SECRET_KEY_FILE=

# --- Structural defaults (runtime needs these) ---
GATEWAY_PORT=8088
QDRANT_URL=http://qdrant:6333
EMBEDDING_MODEL=nvidia/llama-nemotron-embed-vl-1b-v2:free
NIMBUS_DOMAIN=localhost
NIMBUS_GATEWAY_URL=http://localhost:8088/mcp
NIMBUS_ENV_EOF
        chmod 0600 "$INSTALL_DIR/.env"
        echo -e "  Created ${BOLD}\$NIMBUS_HOME/.env${NC} — paste your API keys before first start"
    fi

# 5. Shell Setup
# (The tarball no longer ships a standalone gateway binary; the gateway
# is the OCI image pulled by `nimbus start` via docker compose. The
# PyInstaller nimbus-gateway binary used to be chmod'd here, but
# nothing on the install path executed it. The `docker-compose` block
# we used to extract is also gone — the compose.yaml in the tarball
# is renamed to .yaml by tar -xzf's default, and `nimbus start` reads
# $NIMBUS_HOME/compose.yaml directly. Nothing else needs to be
# chmod'd in the install step.)

chmod +x "$INSTALL_DIR/$BINARY_NAME" 2>/dev/null || true

# Determine shell config
SHELL_CONFIG="$HOME/.bashrc"
case "$SHELL" in
    */zsh)  SHELL_CONFIG="$HOME/.zshrc" ;;
    */bash) SHELL_CONFIG="$HOME/.bashrc" ;;
    *)      [ "$OS" = "darwin" ] && SHELL_CONFIG="$HOME/.zshrc" || SHELL_CONFIG="$HOME/.bashrc" ;;
esac

# The release tarball always extracts to nimbus-$OS-$ARCH (or nimbus
# if a multi-platform release was uploaded as a single binary). We
# use $BINARY_NAME for the launch below.
FINAL_BINARY="$BINARY_NAME"

if ! grep -q "NIMBUS_HOME" "$SHELL_CONFIG" 2>/dev/null; then
    {
        echo ""
        echo "# Nimbus Platform"
        echo "export NIMBUS_HOME=\"$INSTALL_DIR\""
        echo "export PATH=\"\$NIMBUS_HOME:\$PATH\""
        # Re-detect host arch in the shell so the compose file's
        # platform: \${NIMBUS_HOST_ARCH:-linux/arm64} picks the right
        # variant even if the user moves the install between machines.
        echo "export NIMBUS_HOST_ARCH=\"\$(uname -m | sed -E 's/x86_64/amd64/; s/aarch64/arm64/; s|^|linux/|')\""
    } >> "$SHELL_CONFIG"
    echo -e "  Added Nimbus to ${BOLD}$SHELL_CONFIG${NC}"
fi

echo ""
echo -e "  ${BOLD}Nimbus is ready to go.${NC}"
echo ""
echo -e "  ${CYAN}Two ways to use Nimbus:${NC}"
echo -e "  ${CYAN}  1.${NC} Just the gateway (headless, MCP-only): run ${BOLD}nimbus start${NC} and say ${BOLD}N${NC} to the dashboard prompt."
echo -e "  ${CYAN}  2.${NC} Full stack (gateway + agent dashboard): run ${BOLD}nimbus start${NC} and accept the dashboard prompt."
echo -e "  ${CYAN}Re-run later with: ${BOLD}nimbus dashboard install${NC} (or ${BOLD}nimbus dashboard uninstall${NC} to remove)."
echo ""

# 6. Auto-start option
SHOULD_START="n"
if [ -t 0 ]; then
    read -p "  Would you like to start Nimbus now? (y/N) " -n 1 -r REPLY
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SHOULD_START="y"
    fi
elif [ -c /dev/tty ]; then
    if read -p "  Would you like to start Nimbus now? (y/N) " -n 1 -r REPLY < /dev/tty 2>/dev/null; then
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            SHOULD_START="y"
        fi
    fi
fi

if [ "$SHOULD_START" = "y" ]; then
    echo -e "  Starting Nimbus..."
    export NIMBUS_HOME="$INSTALL_DIR"
    export PATH="$INSTALL_DIR:$PATH"
    "$INSTALL_DIR/$FINAL_BINARY" start
else
    echo -e "  To start, please run:"
    echo -e "  ${BOLD}source $SHELL_CONFIG${NC}"
    echo -e "  ${BOLD}nimbus start${NC}\n"
fi

