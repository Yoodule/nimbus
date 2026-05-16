#!/bin/bash
# Nimbus Installer - Premium Edition
# Usage: curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh | bash

set -e

REPO="Yoodule/nimbus"
INSTALL_DIR="${NIMBUS_HOME:-$HOME/.nimbus}"

# --- Aesthetics ---
BLUE='\033[38;5;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${BLUE}${BOLD}"
echo "  --------------------------------------------------"
echo "    N  I  M  B  U  S    G  A  T  E  W  A  Y"
echo "  --------------------------------------------------"
echo -e "${NC}"
echo -e "  ${BOLD}Preparing your environment...${NC}\n"

# 1. System Check
printf "  Detecting system... "
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
[ "$ARCH" = "x86_64" ] && ARCH="amd64"
[[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]] && ARCH="arm64"
echo -e "${GREEN}Done ($OS-$ARCH)${NC}"

# 2. Fetching Release
printf "  Fetching latest release... "
RELEASE_DATA=$(curl -s https://api.github.com/repos/$REPO/releases/latest)
RELEASE_URL=$(echo "$RELEASE_DATA" | grep "browser_download_url" | grep "$OS-$ARCH" | cut -d '"' -f 4)
VERSION=$(echo "$RELEASE_DATA" | grep "tag_name" | cut -d '"' -f 4)
if [ -z "$RELEASE_URL" ]; then
    echo -e "\n  ${RED}Error: Platform not supported ($OS-$ARCH)${NC}"
    exit 1
fi
echo -e "${GREEN}$VERSION${NC}"

# 3. Downloading
echo -e "  Downloading assets..."
TMP_FILE="/tmp/nimbus.tar.gz"
mkdir -p "$INSTALL_DIR"
rm -f "$TMP_FILE"

# Use curl's built-in progress bar
if ! curl -# -L "$RELEASE_URL" -o "$TMP_FILE"; then
    echo -e "\n  ${RED}Error: Download failed.${NC}"
    exit 1
fi

# 4. Extracting
printf "  Installing platform... "
if ! tar -xzf "$TMP_FILE" -C "$INSTALL_DIR"; then
    echo -e "\n  ${RED}Error: Extraction failed.${NC}"
    exit 1
fi
rm -f "$TMP_FILE"
echo -e "${GREEN}Success${NC}"

# 5. Shell Setup
BINARY_NAME="nimbus-$OS-$ARCH"
GATEWAY_NAME="nimbus-gateway-$OS-$ARCH"
[ ! -f "$INSTALL_DIR/$BINARY_NAME" ] && BINARY_NAME="nimbus"
[ ! -f "$INSTALL_DIR/$GATEWAY_NAME" ] && GATEWAY_NAME="nimbus-gateway"

chmod +x "$INSTALL_DIR/$BINARY_NAME" 2>/dev/null || true
chmod +x "$INSTALL_DIR/$GATEWAY_NAME" 2>/dev/null || true

SHELL_CONFIG="$HOME/.bashrc"
[ "$OS" = "darwin" ] && SHELL_CONFIG="$HOME/.zshrc"

if ! grep -q "NIMBUS_HOME" "$SHELL_CONFIG" 2>/dev/null; then
    {
        echo ""
        echo "# Nimbus Platform"
        echo "export NIMBUS_HOME=\"$INSTALL_DIR\""
        echo "export PATH=\"\$NIMBUS_HOME:\$PATH\""
        echo "alias nimbus='$INSTALL_DIR/$BINARY_NAME'"
    } >> "$SHELL_CONFIG"
fi

echo -e "\n  ----------------------------------------"
echo -e "  ${GREEN}${BOLD}Nimbus Gateway is ready.${NC}"
echo -e "  ----------------------------------------"
echo -e "\n  To start, please run:"
echo -e "  ${BOLD}source $SHELL_CONFIG${NC}"
echo -e "  ${BOLD}nimbus start${NC}\n"
