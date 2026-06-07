#!/usr/bin/env bash
# update-nvim.sh - Download and install the latest Neovim (official .tar.gz build, no FUSE needed)

set -euo pipefail  # Exit on error, unset vars, and pipe failures

URL="https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz"
TARBALL="/tmp/nvim-linux-x86_64.tar.gz"
EXTRACT_DIR="/tmp/nvim-extract"   # staged here, tested, then swapped into place
NVIM_DIR="/opt/nvim-linux-x86_64" # final install location
SYMLINK="/usr/local/bin/nvim"     # what ends up on your PATH

# Clean up temp download + staging dir on any exit (success, error, or interrupt)
trap 'rm -rf "$TARBALL" "$EXTRACT_DIR"' EXIT

echo "Downloading latest Neovim tarball..."
if ! curl -fL -o "$TARBALL" "$URL"; then
    echo "Error: Failed to download Neovim tarball"
    exit 1
fi

echo "Extracting..."
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"
if ! tar -C "$EXTRACT_DIR" -xzf "$TARBALL"; then
    echo "Error: Failed to extract tarball"
    exit 1
fi

# The tarball contains a single top-level dir named nvim-linux-x86_64/
STAGED="$EXTRACT_DIR/nvim-linux-x86_64"

echo "Testing extracted binary..."
if ! "$STAGED/bin/nvim" --version &> /dev/null; then
    echo "Error: Extracted Neovim is not working properly"
    exit 1
fi

# Old install (and the previous AppImage file at $SYMLINK) is left untouched until
# the new build is verified above, so a bad download can't break your working nvim.
echo "Installing to $NVIM_DIR (requires sudo)..."
sudo rm -rf "$NVIM_DIR"
if ! sudo mv "$STAGED" "$NVIM_DIR"; then
    echo "Error: Failed to install to $NVIM_DIR"
    exit 1
fi

echo "Linking $SYMLINK -> $NVIM_DIR/bin/nvim (requires sudo)..."
if ! sudo ln -sf "$NVIM_DIR/bin/nvim" "$SYMLINK"; then
    echo "Error: Failed to create symlink at $SYMLINK"
    exit 1
fi

echo "✓ Successfully installed Neovim!"
nvim --version | head -n1

echo ""
echo "Installation location: $NVIM_DIR"
echo "Symlink: $SYMLINK"
echo "Run 'nvim' to start Neovim"
