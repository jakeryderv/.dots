#!/usr/bin/env bash
# update-nvim.sh - Download and install latest Neovim AppImage

set -e  # Exit on error

INSTALL_DIR="/usr/local/bin"
NVIM_PATH="$INSTALL_DIR/nvim"
TEMP_FILE="/tmp/nvim-linux-x86_64.appimage"

echo "Downloading latest Neovim AppImage..."
if ! curl -fL -o "$TEMP_FILE" https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.appimage; then
    echo "Error: Failed to download Neovim AppImage"
    exit 1
fi

echo "Making AppImage executable..."
if ! chmod u+x "$TEMP_FILE"; then
    echo "Error: Failed to make AppImage executable"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo "Testing AppImage..."
if ! "$TEMP_FILE" --version &> /dev/null; then
    echo "Error: Downloaded AppImage is not working properly"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo "Installing to $NVIM_PATH (requires sudo)..."
if ! sudo mv "$TEMP_FILE" "$NVIM_PATH"; then
    echo "Error: Failed to move AppImage to $INSTALL_DIR"
    echo "You may need to run this script with appropriate permissions"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo "✓ Successfully installed Neovim!"
nvim --version | head -n1

echo ""
echo "Installation location: $NVIM_PATH"
echo "Run 'nvim' to start Neovim"
