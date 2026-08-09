#!/usr/bin/env bash
# install-delta.sh - Install or update delta (syntax-highlighting pager for git).
# Re-run anytime: it compares the installed package against the latest release
# and only downloads when a newer one exists. --force reinstalls regardless.
# Assumes: Debian/Ubuntu on x86_64 (dpkg/sudo), curl + jq + sha256sum + awk,
# network. Installs the official .deb after verifying GitHub's SHA-256 digest.

set -euo pipefail # Exit on error, unset vars, and pipe failures

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/lib/github-release.sh
source "$SCRIPT_DIR/lib/github-release.sh"

PACKAGE="git-delta" # what dpkg calls it; the binary it ships is `delta`
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/delta-install.XXXXXX")"

# Clean up the work dir on any exit (success, error, or interrupt)
trap 'rm -rf "$WORK_DIR"' EXIT

gh_parse_force_flag "$@"
gh_require_linux_x86_64
gh_require_cmds dpkg dpkg-query

echo "Resolving latest delta release..."
gh_resolve_latest dandavison/delta
echo "Latest version:    $GH_VERSION"

# dpkg-query exits non-zero when the package is unknown, which is not an error here.
INSTALLED=$(dpkg-query -W -f='${Version}' "$PACKAGE" 2>/dev/null || true)
echo "Installed version: ${INSTALLED:-none}"

if gh_up_to_date "$INSTALLED" "$GH_VERSION"; then
    if ((FORCE == 0)); then
        echo ""
        echo "✓ delta is already up to date."
        exit 0
    fi
    echo "Reinstalling anyway (--force)..."
fi

ASSET_NAME="${PACKAGE}_${GH_VERSION}_amd64.deb"
DEB="$WORK_DIR/$ASSET_NAME"
echo "Downloading delta $GH_VERSION..."
gh_fetch_asset "$ASSET_NAME" "$DEB"

# The existing install stays in place until dpkg swaps it, so a bad download
# cannot leave you without a working delta.
echo "Installing $ASSET_NAME (requires sudo)..."
if ! sudo dpkg -i "$DEB"; then
    echo "Error: failed to install $ASSET_NAME" >&2
    echo "If dpkg reported unmet dependencies, run: sudo apt-get -f install" >&2
    exit 1
fi

echo "Testing binary..."
if ! delta --version >/dev/null 2>&1; then
    echo "Error: installed delta is not working properly" >&2
    exit 1
fi

echo ""
echo "✓ Successfully installed delta!"
delta --version

echo ""
echo "Package: $PACKAGE $(dpkg-query -W -f='${Version}' "$PACKAGE") (remove with: sudo apt remove $PACKAGE)"
echo ""
echo "delta is installed but not yet wired into git. To use it as your pager,"
echo "add to home/gitconfig in this repo:"
echo ""
echo "    [core]"
echo "        pager = delta"
echo "    [interactive]"
echo "        diffFilter = delta --color-only"
echo "    [delta]"
echo "        navigate = true"
echo ""
echo "merge.conflictStyle is already zdiff3 there, which is what delta wants."
