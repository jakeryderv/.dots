#!/usr/bin/env bash
# install-lazygit.sh - Download and install the latest lazygit (GitHub release binary).
# Re-run anytime to update lazygit to the latest version.
# Assumes: Linux x86_64 (apt/sudo), curl + tar, network. Installs latest release.

set -euo pipefail # Exit on error, unset vars, and pipe failures

INSTALL_DIR="/usr/local/bin"
WORK_DIR="/tmp/lazygit-install"
TARBALL="$WORK_DIR/lazygit.tar.gz"

# Clean up the work dir on any exit (success, error, or interrupt)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Resolving latest lazygit version..."
VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" |
	grep -Po '"tag_name": *"v\K[^"]*')
if [ -z "$VERSION" ]; then
	echo "Error: could not determine the latest lazygit version"
	exit 1
fi
echo "Latest version: $VERSION"

URL="https://github.com/jesseduffield/lazygit/releases/download/v${VERSION}/lazygit_${VERSION}_Linux_x86_64.tar.gz"

mkdir -p "$WORK_DIR"

echo "Downloading lazygit $VERSION..."
if ! curl -fL -o "$TARBALL" "$URL"; then
	echo "Error: failed to download lazygit"
	exit 1
fi

echo "Extracting..."
if ! tar -xf "$TARBALL" -C "$WORK_DIR" lazygit; then
	echo "Error: failed to extract lazygit"
	exit 1
fi

echo "Testing binary..."
if ! "$WORK_DIR/lazygit" --version &>/dev/null; then
	echo "Error: extracted lazygit is not working properly"
	exit 1
fi

echo "Installing to $INSTALL_DIR (requires sudo)..."
if ! sudo install "$WORK_DIR/lazygit" -D -t "$INSTALL_DIR"; then
	echo "Error: failed to install lazygit to $INSTALL_DIR"
	exit 1
fi

echo "✓ Successfully installed lazygit!"
lazygit --version | head -n1

echo ""
echo "Installation location: $INSTALL_DIR/lazygit"
echo "Open it in Neovim with <leader>gg (lazygit.nvim)"
