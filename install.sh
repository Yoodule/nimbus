#!/bin/bash
# Nimbus Installer - Premium Edition
# Usage: curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh | bash

set -e

REPO="Yoodule/nimbus"
INSTALL_DIR="${NIMBUS_HOME:-$HOME/.nimbus}"

# --- Aesthetics ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# --- Spinner ---
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
    wait $pid
}

clear
echo -e "${BLUE}${BOLD}"
echo "    _   _ _           _                 "
echo "   | \ | (_)         | |                "
echo "   |  \| |_ _ __ ___ | |__  _   _ ___   "
echo "   | . \` | | '_ \` _ \| '_ \| | | / __|  "
echo "   | |\  | | | | | | | |_) | |_| \__ \  "
echo "   |_| \_|_|_| |_| |_|_.__/ \__,_|___/  "
echo -e "${NC}"
echo -e "  ${BOLD}Preparing your Nimbus environment...${NC}\n"

# 1. System Check
printf "  Detecting system... "
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
[ "$ARCH" = "x86_64" ] && ARCH="amd64"
[[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]] && ARCH="arm64"
echo -e "${GREEN}Done${NC}"

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
printf "  Downloading assets... "
TMP_FILE="/tmp/nimbus.tar.gz"
mkdir -p "$INSTALL_DIR"
# Remove old temp file if exists
rm -f "$TMP_FILE"
# Download with error capture
if ! curl -sL "$RELEASE_URL" -o "$TMP_FILE"; then
    echo -e "\n  ${RED}Error: Download failed.${NC}"
    exit 1
fi
echo -e "${GREEN}Complete${NC}"

# 4. Extracting
printf "  Installing platform... "
if ! tar -xzf "$TMP_FILE" -C "$INSTALL_DIR"; then
    echo -e "\n  ${RED}Error: Extraction failed.${NC}"
    exit 1
fi
rm -f "$TMP_FILE"
echo -e "${GREEN}Ready${NC}"

# 5. Shell Setup
# Determine binary names based on the tarball structure
BINARY_NAME="nimbus-$OS-$ARCH"
GATEWAY_NAME="nimbus-gateway-$OS-$ARCH"

# Fallback if names are simple
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
echo -e "  ${GREEN}${BOLD}Nimbus is now ready.${NC}"
echo -e "  ----------------------------------------"
echo -e "\n  To begin, please run:"
echo -e "  ${BOLD}source $SHELL_CONFIG${NC}"
echo -e "  ${BOLD}nimbus start${NC}\n"
