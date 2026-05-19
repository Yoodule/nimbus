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
    RELEASE_DATA=$(curl -s https://api.github.com/repos/$REPO/releases/latest)
    
    # Try native platform first
    RELEASE_URL=$(echo "$RELEASE_DATA" | grep "browser_download_url" | grep "$OS-$ARCH" | cut -d '"' -f 4)
    
    # Fallback for Apple Silicon (try amd64 if arm64 not found)
    if [ -z "$RELEASE_URL" ] && [ "$OS" = "darwin" ] && [ "$ARCH" = "arm64" ]; then
        printf "(arm64 not found, trying amd64) "
        RELEASE_URL=$(echo "$RELEASE_DATA" | grep "browser_download_url" | grep "darwin-amd64" | cut -d '"' -f 4)
    fi

    VERSION=$(echo "$RELEASE_DATA" | grep "tag_name" | cut -d '"' -f 4)
    
    if [ -z "$RELEASE_URL" ]; then
        echo -e "\n  ${BOLD}Error:${NC} Platform not supported ($OS-$ARCH)"
        echo "  Please build from source: https://github.com/Yoodule/nimbus"
        exit 1
    fi
    echo -e "${BLUE}$VERSION${NC}"

    # 3. Downloading
    echo -e "  Downloading assets..."
    TMP_FILE="/tmp/nimbus.tar.gz"
    mkdir -p "$INSTALL_DIR"
    rm -f "$TMP_FILE"

    if ! curl -# -L "$RELEASE_URL" -o "$TMP_FILE"; then
        echo -e "\n  ${BOLD}Error:${NC} Download failed."
        exit 1
    fi

    # 4. Extracting
    printf "  Installing Nimbus... "
    if ! tar -xzf "$TMP_FILE" -C "$INSTALL_DIR"; then
        echo -e "\n  ${BOLD}Error:${NC} Extraction failed."
        exit 1
    fi
    rm -f "$TMP_FILE"
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

