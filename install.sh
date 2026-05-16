#!/bin/bash
# Nimbus Installer - Premium Edition
# Usage: curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh | bash

set -e

REPO="Yoodule/nimbus"
INSTALL_DIR="${NIMBUS_HOME:-$HOME/.nimbus}"

# --- Aesthetics ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

# --- Spinner ---
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
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
    echo -e "\n  Error: Platform not supported ($OS-$ARCH)"
    exit 1
fi
echo -e "${GREEN}$VERSION${NC}"

# 3. Downloading
printf "  Downloading assets... "
TMP_FILE="/tmp/nimbus.tar.gz"
mkdir -p "$INSTALL_DIR"
(curl -sL "$RELEASE_URL" -o "$TMP_FILE") &
spinner $!
echo -e "${GREEN}Complete${NC}"

# 4. Extracting
printf "  Installing platform... "
(tar -xzf "$TMP_FILE" -C "$INSTALL_DIR") &
spinner $!
rm "$TMP_FILE"
echo -e "${GREEN}Ready${NC}"

# 5. Shell Setup
BINARY_NAME="nimbus-$OS-$ARCH"
[ ! -f "$INSTALL_DIR/$BINARY_NAME" ] && BINARY_NAME="nimbus"
chmod +x "$INSTALL_DIR/$BINARY_NAME" 2>/dev/null || true

SHELL_CONFIG="$HOME/.bashrc"
[ "$OS" = "darwin" ] && SHELL_CONFIG="$HOME/.zshrc"

if ! grep -q "NIMBUS_HOME" "$SHELL_CONFIG" 2>/dev/null; then
    {
        echo ""
        echo "# Nimbus Platform"
        echo "export NIMBUS_HOME=\"$INSTALL_DIR\""
        echo "export PATH=\"\$NIMBUS_HOME:\$PATH\""
        echo "alias nimbus='nimbus-$OS-$ARCH'"
    } >> "$SHELL_CONFIG"
fi

echo -e "\n  ----------------------------------------"
echo -e "  ${GREEN}${BOLD}Nimbus is now ready.${NC}"
echo -e "  ----------------------------------------"
echo -e "\n  To begin, please run:"
echo -e "  ${BOLD}source $SHELL_CONFIG${NC}"
echo -e "  ${BOLD}nimbus start${NC}\n"
