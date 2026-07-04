#!/bin/bash
# Nimbus Installer - Premium Edition
# Usage: curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh | bash

set -e

REPO="Yoodule/nimbus"
INSTALL_DIR="${NIMBUS_HOME:-$HOME/.nimbus}"

# --- Aesthetics (Yoodule Style: High Contrast, Minimalist) ---
BOLD='\033[1m'
BLUE='\033[34m'
CYAN='\033[36m'
NC='\033[0m'

clear
echo ""
echo -e "      ${BOLD}N  I  M  B  U  S${NC}"
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

# 2. Check if we are in a local repo for Dev Install
if [[ -f "nimbus.py" && -d "src" ]]; then
    echo -e "  ${BOLD}Local repository detected.${NC} Installing from source..."
    mkdir -p "$INSTALL_DIR"
    
    # Sync current repo to install dir (selective)
    printf "  Syncing files... "
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --exclude '.git' --exclude '.venv' --exclude 'node_modules' --exclude '.next' --exclude 'dist' --exclude 'release' --exclude 'build' --exclude 'dashboard' . "$INSTALL_DIR/"
        # Copy all binaries from dist
        [ -d "dist" ] && cp -r dist/* "$INSTALL_DIR/" 2>/dev/null || true
    else
        # Fallback
        cp nimbus.py pyproject.toml uv.lock "$INSTALL_DIR/"
        cp -r src "$INSTALL_DIR/"
        [ -d "dist" ] && cp -r dist/* "$INSTALL_DIR/" 2>/dev/null || true
    fi
    echo -e "${BLUE}Done${NC}"
    
    BINARY_NAME="nimbus.py"
    IS_SOURCE=true
else
    # 2. Fetching Release
    printf "  Fetching latest release... "
    # Resolve version when NIMBUS_VERSION is unset. /releases/latest returns
    # the newest non-draft, non-prerelease release. If you need a specific
    # build (including prereleases), set NIMBUS_VERSION explicitly.
    if [ -z "${NIMBUS_VERSION:-}" ]; then
        # Default to the most recent known release. Override with
        # `NIMBUS_VERSION=vX.Y.Z bash install.sh` for a specific build.
        NIMBUS_VERSION="${NIMBUS_VERSION:-v1.0.3}"
    fi
    if [ -z "$NIMBUS_VERSION" ]; then
        echo -e "\n  ${BOLD}Error:${NC} Could not resolve a release version. Set NIMBUS_VERSION=vX.Y.Z and retry."
        exit 1
    fi

    RELEASE_BASE="https://github.com/$REPO/releases/download/$NIMBUS_VERSION"
    RELEASE_URL="${RELEASE_BASE}/nimbus-$OS-$ARCH.tar.gz"

    # Fallback for Apple Silicon: try amd64 when arm64 isn't published.
    if [ ! "$(curl -fsSI -o /dev/null -w '%{http_code}' "$RELEASE_URL")" = "200" ] \
        && [ "$OS" = "darwin" ] && [ "$ARCH" = "arm64" ]; then
        printf "(arm64 not found, trying amd64) "
        RELEASE_URL="${RELEASE_BASE}/nimbus-darwin-amd64.tar.gz"
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
    IS_SOURCE=false
fi

# 5. Shell Setup
GATEWAY_NAME="nimbus-gateway-$OS-$ARCH"
[ ! -f "$INSTALL_DIR/$GATEWAY_NAME" ] && GATEWAY_NAME="nimbus-gateway"

chmod +x "$INSTALL_DIR/$BINARY_NAME" 2>/dev/null || true
chmod +x "$INSTALL_DIR/$GATEWAY_NAME" 2>/dev/null || true

# Determine shell config
SHELL_CONFIG="$HOME/.bashrc"
case "$SHELL" in
    */zsh)  SHELL_CONFIG="$HOME/.zshrc" ;;
    */bash) SHELL_CONFIG="$HOME/.bashrc" ;;
    *)      [ "$OS" = "darwin" ] && SHELL_CONFIG="$HOME/.zshrc" || SHELL_CONFIG="$HOME/.bashrc" ;;
esac

# Create the nimbus wrapper command if it's source
if [ "$IS_SOURCE" = true ]; then
    cat > "$INSTALL_DIR/nimbus" <<EOF
#!/bin/bash
export NIMBUS_HOME="$INSTALL_DIR"
python3 "\$NIMBUS_HOME/nimbus.py" "\$@"
EOF
    chmod +x "$INSTALL_DIR/nimbus"
    FINAL_BINARY="nimbus"
else
    FINAL_BINARY="$BINARY_NAME"
fi

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
echo -e "  ${CYAN}Note:${NC} The Dashboard is a separate optional component."
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

