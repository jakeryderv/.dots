#!/usr/bin/env bash
# install-lazygit.sh - Download and install the latest lazygit (GitHub release binary).
# Re-run anytime to update lazygit to the latest version.
# Assumes: Linux x86_64 (sudo), curl + jq + sha256sum + tar, network.
# Installs the latest release after verifying GitHub's SHA-256 asset digest.

set -euo pipefail # Exit on error, unset vars, and pipe failures

INSTALL_DIR="/usr/local/bin"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/lazygit-install.XXXXXX")"
TARBALL="$WORK_DIR/lazygit.tar.gz"

# Clean up the work dir on any exit (success, error, or interrupt)
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

echo "Resolving latest lazygit release..."
RELEASE_JSON=$(curl -fsSL --retry 3 "https://api.github.com/repos/jesseduffield/lazygit/releases/latest")
VERSION=$(printf '%s' "$RELEASE_JSON" | jq -er '.tag_name | ltrimstr("v")')
ASSET_NAME="lazygit_${VERSION}_linux_x86_64.tar.gz"
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
echo "Latest version: $VERSION"

echo "Downloading lazygit $VERSION..."
if ! curl -fL -o "$TARBALL" "$URL"; then
    echo "Error: failed to download lazygit"
    exit 1
fi

ACTUAL_SHA256=$(sha256sum "$TARBALL" | awk '{print $1}')
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
    echo "Error: SHA-256 verification failed for $ASSET_NAME" >&2
    exit 1
fi
echo "Verified SHA-256: $ACTUAL_SHA256"

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
