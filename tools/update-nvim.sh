#!/usr/bin/env bash
# update-nvim.sh - Download and install the latest Neovim (official .tar.gz build, no FUSE needed)
# Assumes: Linux x86_64 (sudo for /opt + /usr/local/bin), curl + jq +
# sha256sum + tar, network. Installs stable after verifying the release digest.

set -euo pipefail # Exit on error, unset vars, and pipe failures

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/lib/github-release.sh
source "$SCRIPT_DIR/lib/github-release.sh"

ASSET_NAME="nvim-linux-x86_64.tar.gz"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/nvim-install.XXXXXX")"
TARBALL="$WORK_DIR/$ASSET_NAME"
EXTRACT_DIR="$WORK_DIR/extract"   # staged here, tested, then swapped into place
NVIM_DIR="/opt/nvim-linux-x86_64" # final install location
SYMLINK="/usr/local/bin/nvim"     # what ends up on your PATH

# Clean up temp download + staging dir on any exit (success, error, or interrupt)
trap 'rm -rf "$WORK_DIR"' EXIT

gh_require_linux_x86_64
gh_require_cmds tar

# Resolved by tag, not `latest`: Neovim's latest release can be a nightly
# pre-release, while `stable` is a moving tag that always points at the
# current stable build.
echo "Resolving the stable Neovim release..."
gh_resolve_tag neovim/neovim stable

echo "Downloading latest Neovim tarball..."
gh_fetch_asset "$ASSET_NAME" "$TARBALL"

echo "Extracting..."
mkdir -p "$EXTRACT_DIR"
if ! tar -C "$EXTRACT_DIR" -xzf "$TARBALL"; then
    echo "Error: Failed to extract tarball"
    exit 1
fi

# The tarball contains a single top-level dir named nvim-linux-x86_64/
STAGED="$EXTRACT_DIR/nvim-linux-x86_64"

echo "Testing extracted binary..."
if ! "$STAGED/bin/nvim" --version &>/dev/null; then
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
