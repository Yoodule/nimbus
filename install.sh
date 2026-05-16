#!/bin/bash
# Nimbus Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/yoodule/nimbus-gateway/main/install.sh | bash

set -e

REPO="Yoodule/nimbus"
INSTALL_DIR="$HOME/.nimbus"

# Detect OS and Arch
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
fi

echo "Installing Nimbus for $OS-$ARCH..."

# Get latest release URL from GitHub API
RELEASE_URL=$(curl -s https://api.github.com/repos/$REPO/releases/latest | grep "browser_download_url" | grep "$OS-$ARCH" | cut -d '"' -f 4)

if [ -z "$RELEASE_URL" ]; then
    echo "Error: Could not find a release for $OS-$ARCH. Please check $REPO releases."
    exit 1
fi

# Download and extract
mkdir -p "$INSTALL_DIR"
echo "Fetching Nimbus v1.0.1..."
curl --progress-bar -L "$RELEASE_URL" | tar -xz -C "$INSTALL_DIR"

# Ensure binaries are executable
chmod +x "$INSTALL_DIR/nimbus-$OS-$ARCH"
chmod +x "$INSTALL_DIR/nimbus-gateway-$OS-$ARCH"

# Create symlinks or aliases
if [ "$OS" = "darwin" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    SHELL_CONFIG="$HOME/.bashrc"
fi

if ! grep -q "NIMBUS_HOME" "$SHELL_CONFIG" 2>/dev/null; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Nimbus PATH" >> "$SHELL_CONFIG"
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_CONFIG"
    echo "alias nimbus='nimbus-$OS-$ARCH'" >> "$SHELL_CONFIG"
    echo "Added Nimbus to $SHELL_CONFIG"
fi

echo ""
echo "Nimbus installed successfully!"
echo "Please restart your terminal or run 'source $SHELL_CONFIG' to start using nimbus."
echo "Run 'nimbus start' to launch the platform."
