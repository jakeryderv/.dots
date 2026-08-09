#!/usr/bin/env bash
# install-lazygit.sh - Install or update lazygit (GitHub release binary).
# Re-run anytime: it compares the installed binary against the latest release
# and only downloads when a newer one exists. --force reinstalls regardless.
# Assumes: Linux x86_64 (sudo), curl + jq + sha256sum + awk + tar + dpkg,
# network. dpkg is used only for `--compare-versions`.
# Installs the latest release after verifying GitHub's SHA-256 asset digest.

set -euo pipefail # Exit on error, unset vars, and pipe failures

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/lib/github-release.sh
source "$SCRIPT_DIR/lib/github-release.sh"

INSTALL_DIR="/usr/local/bin"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/lazygit-install.XXXXXX")"
TARBALL="$WORK_DIR/lazygit.tar.gz"

# Clean up the work dir on any exit (success, error, or interrupt)
trap 'rm -rf "$WORK_DIR"' EXIT

gh_parse_force_flag "$@"
gh_require_linux_x86_64
gh_require_cmds tar dpkg

echo "Resolving latest lazygit release..."
gh_resolve_latest jesseduffield/lazygit
echo "Latest version:    $GH_VERSION"

# `lazygit --version` prints comma-separated key=value fields; take the field
# whose key is exactly `version` (a greedy match would grab `git version=`).
INSTALLED=""
if command -v lazygit >/dev/null 2>&1; then
    INSTALLED=$(lazygit --version 2>/dev/null | head -n1 | tr ',' '\n' |
        sed -n 's/^[[:space:]]*version=//p' | head -n1)
fi
echo "Installed version: ${INSTALLED:-none}"

if gh_up_to_date "$INSTALLED" "$GH_VERSION"; then
    if ((FORCE == 0)); then
        echo ""
        echo "✓ lazygit is already up to date."
        exit 0
    fi
    echo "Reinstalling anyway (--force)..."
fi

ASSET_NAME="lazygit_${GH_VERSION}_linux_x86_64.tar.gz"
echo "Downloading lazygit $GH_VERSION..."
gh_fetch_asset "$ASSET_NAME" "$TARBALL"

echo "Extracting..."
if ! tar -xf "$TARBALL" -C "$WORK_DIR" lazygit; then
    echo "Error: failed to extract lazygit" >&2
    exit 1
fi

echo "Testing binary..."
if ! "$WORK_DIR/lazygit" --version &>/dev/null; then
    echo "Error: extracted lazygit is not working properly" >&2
    exit 1
fi

echo "Installing to $INSTALL_DIR (requires sudo)..."
if ! sudo install "$WORK_DIR/lazygit" -D -t "$INSTALL_DIR"; then
    echo "Error: failed to install lazygit to $INSTALL_DIR" >&2
    exit 1
fi

echo "✓ Successfully installed lazygit!"
"$INSTALL_DIR/lazygit" --version | head -n1

echo ""
echo "Installation location: $INSTALL_DIR/lazygit"
echo "Open it in Neovim with <leader>gg (lazygit.nvim)"
