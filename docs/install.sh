#!/bin/bash
# Nimbus Installer
# Usage: curl -fsSL https://nimbus.yoodule.com/install.sh | bash
#   Override:  NIMBUS_VERSION=vX.Y.Z bash -c "$(curl -fsSL https://nimbus.yoodule.com/install.sh)"

set -e

REPO="Yoodule/nimbus"
INSTALL_DIR="${NIMBUS_HOME:-$HOME/.nimbus}"

# --- Aesthetics (Yoodule Style: High Contrast, Minimalist) ---
BOLD='\033[1m'
WHITE='\033[37m'
DIM='\033[2m'
BLUE='\033[34m'
CYAN='\033[36m'
NC='\033[0m'

clear
echo ""
echo -e "  ${BOLD}${WHITE}█▄  █  █  █▀▄▀█  █▀▄   █ █  █▀${NC}"
echo -e "  ${BOLD}${WHITE}█ ▀▄█  █  █ ▀ █  ██▄   █▄█  ▄█${NC}"
echo -e "  ${BOLD}${WHITE}Your 24/7 Employee${NC}"
echo -e "  ${WHITE}https://nimbus.yoodule.com${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────${NC}"
echo ""
echo -e "  Preparing your environment..."

# 1. System Check
printf "  Detecting system... "
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
[ "$ARCH" = "x86_64" ] && ARCH="amd64"
[[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]] && ARCH="arm64"
echo -e "${BLUE}Done ($OS-$ARCH)${NC}"

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

# 2. Resolve version
# /releases/latest returns the newest non-draft, non-prerelease release. The
# fallback is a frozen-in-time version used only when the API is unreachable
# (offline install, rate limit, etc.) — bump it when cutting releases.
printf "  Fetching latest release... "
if [ -z "${NIMBUS_VERSION:-}" ]; then
    RESOLVED=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
        2>/dev/null | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    if [ -n "$RESOLVED" ]; then
        NIMBUS_VERSION="$RESOLVED"
    else
        NIMBUS_VERSION="v1.0.3"
    fi
fi
if [ -z "$NIMBUS_VERSION" ]; then
    echo -e "\n  ${BOLD}Error:${NC} Could not resolve a release version. Set NIMBUS_VERSION=vX.Y.Z and retry."
    exit 1
fi

RELEASE_BASE="https://github.com/$REPO/releases/download/$NIMBUS_VERSION"
ASSET_NAME="nimbus-$OS-$ARCH.tar.gz"
DASHBOARD_ASSET="dashboard.tar.gz"
RELEASE_URL="${RELEASE_BASE}/$ASSET_NAME"
DASHBOARD_URL="${RELEASE_BASE}/$DASHBOARD_ASSET"
echo -e "${BLUE}$NIMBUS_VERSION${NC}"

# 3. Downloading + verifying
echo -e "  Downloading assets..."
TMP_DIR=$(mktemp -d)
TMP_FILE="$TMP_DIR/$ASSET_NAME"
TMP_DASHBOARD="$TMP_DIR/$DASHBOARD_ASSET"
TMP_SUMS="$TMP_DIR/SHA256SUMS"
trap 'rm -rf "$TMP_DIR"' EXIT

# Fetch SHA256SUMS first so we can verify every asset against the same sidecar.
# The grep is positional — SHA256SUMS lines look like "<hex>  <filename>".
if ! curl -fsSL "${RELEASE_BASE}/SHA256SUMS" -o "$TMP_SUMS"; then
    echo -e "\n  ${BOLD}Error:${NC} Could not download SHA256SUMS for $NIMBUS_VERSION."
    echo "  Verify the release at: $RELEASE_BASE"
    exit 1
fi

download_and_verify() {
    local url="$1" name="$2" out="$3"
    # curl -# (interactive progress bar) breaks against HTTP/2 servers with
    # curl error 92 PROTOCOL_ERROR — use -sS for silent transfer with errors
    # on failure. The "Downloading assets..." banner above tells the user
    # something is happening.
    if ! curl -sSfL "$url" -o "$out"; then
        echo -e "\n  ${BOLD}Error:${NC} Download failed ($name)."
        echo "  URL: $url"
        return 1
    fi
    if ! grep -E "^[0-9a-f]{64}  ${name}\$" "$TMP_SUMS" \
        | (cd "$TMP_DIR" && sha256sum -c --strict -) >/dev/null; then
        echo -e "\n  ${BOLD}Error:${NC} SHA256 verification failed for $name."
        echo "  Refusing to install. Verify the release at $RELEASE_BASE manually."
        return 1
    fi
    printf "  Checksum verified for %s... ${BLUE}OK${NC}\n" "$name"
}

if ! download_and_verify "$RELEASE_URL" "$ASSET_NAME" "$TMP_FILE"; then
    exit 1
fi

# 4. Extracting
printf "  Installing Nimbus... "
mkdir -p "$INSTALL_DIR"
if ! tar -xzf "$TMP_FILE" -C "$INSTALL_DIR"; then
    echo -e "\n  ${BOLD}Error:${NC} Extraction failed."
    exit 1
fi
echo -e "${BLUE}Success${NC}"

chmod +x "$INSTALL_DIR/nimbus" 2>/dev/null || true
chmod +x "$INSTALL_DIR/nimbus-gateway" 2>/dev/null || true

# 5. Optional dashboard install
# The dashboard ships as a separate tarball on the same release. The CLI starts
# fine without it (gateway is headless), but most users want it. We default to
# "yes" so the user has to opt out — the install fails loud if the download or
# checksum is bad, so a missing/broken dashboard just skips the install and
# leaves the CLI working.
install_dashboard() {
    if ! download_and_verify "$DASHBOARD_URL" "$DASHBOARD_ASSET" "$TMP_DASHBOARD"; then
        echo -e "  ${CYAN}Skipping dashboard install (asset not available for this release).${NC}"
        return 0
    fi
    if ! tar -xzf "$TMP_DASHBOARD" -C "$INSTALL_DIR"; then
        echo -e "  ${CYAN}Skipping dashboard install (extraction failed).${NC}"
        return 0
    fi
    echo -e "  Dashboard installed at: ${BOLD}$INSTALL_DIR/dashboard${NC}"
}

if [ -t 0 ]; then
    read -p "  Would you like to install the Nimbus Dashboard too? (Y/n) " -n 1 -r DASH_REPLY
    echo
    case "$DASH_REPLY" in
        [nN]) echo -e "  ${CYAN}Skipping dashboard install.${NC}" ;;
        *)    install_dashboard ;;
    esac
else
    # Non-interactive (curl-piped, no TTY) — install by default.
    install_dashboard
fi

# 6. Shell Setup
SHELL_CONFIG="$HOME/.bashrc"
case "$SHELL" in
    */zsh)  SHELL_CONFIG="$HOME/.zshrc" ;;
    */bash) SHELL_CONFIG="$HOME/.bashrc" ;;
    *)      [ "$OS" = "darwin" ] && SHELL_CONFIG="$HOME/.zshrc" || SHELL_CONFIG="$HOME/.bashrc" ;;
esac

if ! grep -q "NIMBUS_HOME" "$SHELL_CONFIG" 2>/dev/null; then
    {
        echo ""
        echo "# Nimbus Platform"
        echo "export NIMBUS_HOME=\"$INSTALL_DIR\""
        echo "export PATH=\"\$NIMBUS_HOME:\$PATH\""
    } >> "$SHELL_CONFIG"
    echo -e "  Added Nimbus to ${BOLD}$SHELL_CONFIG${NC}"
fi

echo ""
echo -e "  ${BOLD}Nimbus is ready to go.${NC}"
echo ""

# 7. Auto-start option
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
    "$INSTALL_DIR/nimbus" start
else
    echo -e "  To start, please run:"
    echo -e "  ${BOLD}source $SHELL_CONFIG${NC}"
    echo -e "  ${BOLD}nimbus start${NC}\n"
fi
