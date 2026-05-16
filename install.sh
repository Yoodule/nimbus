#!/bin/bash
# Nimbus Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh | bash

set -e

REPO="Yoodule/nimbus"
INSTALL_DIR="${NIMBUS_HOME:-$HOME/.nimbus}"

# --- UI Helpers ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

print_step() { echo -e "${BLUE}${BOLD}==>${NC} ${BOLD}$1${NC}"; }
print_success() { echo -e "${GREEN}${BOLD}✓${NC} ${BOLD}$1${NC}"; }
print_error() { echo -e "${RED}${BOLD}Error:${NC} $1"; }

clear
echo -e "${BLUE}"
echo "    _   _ _           _                 "
echo "   | \ | (_)         | |                "
echo "   |  \| |_ _ __ ___ | |__  _   _ ___   "
echo "   | . \` | | '_ \` _ \| '_ \| | | / __|  "
echo "   | |\  | | | | | | | |_) | |_| \__ \  "
echo "   |_| \_|_|_| |_| |_|_.__/ \__,_|___/  "
echo -e "${NC}"
echo -e "${BOLD}Welcome to the Nimbus Installer${NC}"
echo "----------------------------------------"

# Detect OS and Arch
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
fi

print_step "Detecting system: $OS-$ARCH"

# Get latest release URL
print_step "Fetching latest release information..."
RELEASE_DATA=$(curl -s https://api.github.com/repos/$REPO/releases/latest)
RELEASE_URL=$(echo "$RELEASE_DATA" | grep "browser_download_url" | grep "$OS-$ARCH" | cut -d '"' -f 4)
VERSION=$(echo "$RELEASE_DATA" | grep "tag_name" | cut -d '"' -f 4)

if [ -z "$RELEASE_URL" ]; then
    print_error "Could not find a release for $OS-$ARCH. Please check $REPO releases."
    exit 1
fi

print_success "Found Nimbus $VERSION"

# Download and extract
mkdir -p "$INSTALL_DIR"
TMP_FILE="/tmp/nimbus.tar.gz"

print_step "Downloading Nimbus..."
curl -# -L "$RELEASE_URL" -o "$TMP_FILE"

print_step "Installing to $INSTALL_DIR..."
tar -xzf "$TMP_FILE" -C "$INSTALL_DIR"
rm "$TMP_FILE"

# Ensure binaries are executable
BINARY_NAME="nimbus-$OS-$ARCH"
GATEWAY_NAME="nimbus-gateway-$OS-$ARCH"

# Check if binaries exist (handle cases where naming might be simpler)
if [ ! -f "$INSTALL_DIR/$BINARY_NAME" ]; then
    BINARY_NAME="nimbus"
fi
if [ ! -f "$INSTALL_DIR/$GATEWAY_NAME" ]; then
    GATEWAY_NAME="nimbus-gateway"
fi

chmod +x "$INSTALL_DIR/$BINARY_NAME" 2>/dev/null || true
chmod +x "$INSTALL_DIR/$GATEWAY_NAME" 2>/dev/null || true

# Setup Shell
if [ "$OS" = "darwin" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    SHELL_CONFIG="$HOME/.bashrc"
fi

print_step "Configuring shell: $SHELL_CONFIG"

if ! grep -q "NIMBUS_HOME" "$SHELL_CONFIG" 2>/dev/null; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Nimbus configuration" >> "$SHELL_CONFIG"
    echo "export NIMBUS_HOME=\"$INSTALL_DIR\"" >> "$SHELL_CONFIG"
    echo "export PATH=\"\$NIMBUS_HOME:\$PATH\"" >> "$SHELL_CONFIG"
    echo "alias nimbus='nimbus-$OS-$ARCH'" >> "$SHELL_CONFIG"
    print_success "Added Nimbus to PATH and created 'nimbus' alias."
fi

echo "----------------------------------------"
print_success "Nimbus installed successfully!"
echo ""
echo -e "To start using Nimbus, please run:"
echo -e "  ${BOLD}source $SHELL_CONFIG${NC}"
echo -e "  ${BOLD}nimbus start${NC}"
echo ""
