#!/usr/bin/env bash
# install-delta.sh - Install or update delta (syntax-highlighting pager for git).
# Re-run anytime: it compares the installed package against the latest release
# and only downloads when a newer one exists. --force reinstalls regardless.
# Assumes: Debian/Ubuntu on x86_64 (dpkg/sudo), curl + jq + sha256sum + awk,
# network. Installs the official .deb after verifying GitHub's SHA-256 digest.

set -euo pipefail # Exit on error, unset vars, and pipe failures

REPO="dandavison/delta"
PACKAGE="git-delta" # what dpkg calls it; the binary it ships is `delta`
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/delta-install.XXXXXX")"

# Clean up the work dir on any exit (success, error, or interrupt)
trap 'rm -rf "$WORK_DIR"' EXIT

FORCE=0
case "${1-}" in
"") ;;
-f | --force) FORCE=1 ;;
-h | --help)
    echo "usage: ${0##*/} [--force]"
    echo "  --force  reinstall even when already at the latest version"
    exit 0
    ;;
*)
    echo "Error: unknown argument '$1' (try --help)" >&2
    exit 2
    ;;
esac

if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
    echo "Error: this helper supports Linux x86_64 only" >&2
    exit 1
fi

for command in curl jq sha256sum awk dpkg dpkg-query; do
    command -v "$command" >/dev/null 2>&1 || {
        echo "Error: required command '$command' was not found" >&2
        exit 1
    }
done

echo "Resolving latest delta release..."
RELEASE_JSON=$(curl -fsSL --retry 3 "https://api.github.com/repos/$REPO/releases/latest")
VERSION=$(printf '%s' "$RELEASE_JSON" | jq -er '.tag_name | ltrimstr("v")')
echo "Latest version:    $VERSION"

# dpkg-query exits non-zero when the package is unknown, which is not an error here.
INSTALLED=$(dpkg-query -W -f='${Version}' "$PACKAGE" 2>/dev/null || true)
echo "Installed version: ${INSTALLED:-none}"

# dpkg does the version comparison so upstream's scheme is honored rather than
# a string compare, which would call 0.9.0 newer than 0.19.2.
if [[ -n "$INSTALLED" ]] && dpkg --compare-versions "$INSTALLED" ge "$VERSION"; then
    if ((FORCE == 0)); then
        echo ""
        echo "✓ delta is already up to date."
        exit 0
    fi
    echo "Reinstalling anyway (--force)..."
fi

ASSET_NAME="${PACKAGE}_${VERSION}_amd64.deb"
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

DEB="$WORK_DIR/$ASSET_NAME"
echo "Downloading delta $VERSION..."
if ! curl -fL -o "$DEB" "$URL"; then
    echo "Error: failed to download delta" >&2
    exit 1
fi

ACTUAL_SHA256=$(sha256sum "$DEB" | awk '{print $1}')
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
    echo "Error: SHA-256 verification failed for $ASSET_NAME" >&2
    exit 1
fi
echo "Verified SHA-256: $ACTUAL_SHA256"

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
