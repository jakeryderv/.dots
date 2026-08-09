#!/usr/bin/env bash
# update-nvim.sh - Download and install the latest Neovim (official .tar.gz build, no FUSE needed)
# Assumes: Linux x86_64 (sudo for /opt + /usr/local/bin), curl + jq +
# sha256sum + tar, network. Installs stable after verifying the release digest.

set -euo pipefail # Exit on error, unset vars, and pipe failures

API="https://api.github.com/repos/neovim/neovim/releases/tags/stable"
ASSET_NAME="nvim-linux-x86_64.tar.gz"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/nvim-install.XXXXXX")"
TARBALL="$WORK_DIR/$ASSET_NAME"
EXTRACT_DIR="$WORK_DIR/extract"   # staged here, tested, then swapped into place
NVIM_DIR="/opt/nvim-linux-x86_64" # final install location
SYMLINK="/usr/local/bin/nvim"     # what ends up on your PATH

# Clean up temp download + staging dir on any exit (success, error, or interrupt)
trap 'rm -rf "$WORK_DIR"' EXIT

if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
    echo "Error: this helper supports Linux x86_64 only" >&2
    exit 1
fi

for command in curl jq sha256sum tar; do
    command -v "$command" >/dev/null 2>&1 || {
        echo "Error: required command '$command' was not found" >&2
        exit 1
    }
done

echo "Resolving the stable Neovim release..."
RELEASE_JSON=$(curl -fsSL --retry 3 "$API")
ASSET=$(printf '%s' "$RELEASE_JSON" | jq -cer --arg name "$ASSET_NAME" '
	[.assets[] | select(.name == $name)]
	| if length == 1 then .[0] else error("expected exactly one matching asset") end
')
URL=$(printf '%s' "$ASSET" | jq -er '.browser_download_url')
DIGEST=$(printf '%s' "$ASSET" | jq -er '.digest')
[[ "$DIGEST" =~ ^sha256:([0-9a-fA-F]{64})$ ]] || {
    echo "Error: invalid SHA-256 digest for $ASSET_NAME" >&2
    exit 1
}
EXPECTED_SHA256="${BASH_REMATCH[1],,}"

echo "Downloading latest Neovim tarball..."
if ! curl -fL -o "$TARBALL" "$URL"; then
    echo "Error: Failed to download Neovim tarball"
    exit 1
fi

ACTUAL_SHA256=$(sha256sum "$TARBALL" | awk '{print $1}')
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
    echo "Error: SHA-256 verification failed for $ASSET_NAME" >&2
    exit 1
fi
echo "Verified SHA-256: $ACTUAL_SHA256"

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
