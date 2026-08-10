#!/usr/bin/env bash
# install-kanata.sh - Install or update kanata (GitHub release binary).
# Re-run anytime: it compares the installed binary against the latest release
# and only downloads when a newer one exists. --force reinstalls regardless.
# Assumes: Linux x86_64 (sudo), curl + jq + sha256sum + awk + unzip + dpkg,
# network. dpkg is used only for `--compare-versions`.
# Installs the latest release after verifying GitHub's SHA-256 asset digest.
#
# Installs the binary ONLY. kanata also needs read access to /dev/input/event*
# and write access to /dev/uinput, which is a system change this script leaves
# to you deliberately -- adding yourself to the `input` group grants anything
# running as you the ability to read every keystroke. The exact commands are in
# docs/kanata.md and are echoed at the end of a successful run.

set -euo pipefail # Exit on error, unset vars, and pipe failures

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/lib/github-release.sh
source "$SCRIPT_DIR/lib/github-release.sh"

INSTALL_DIR="/usr/local/bin"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/kanata-install.XXXXXX")"
ARCHIVE="$WORK_DIR/kanata.zip"

# The upstream zip ships two builds. Take the one WITHOUT `cmd` support: the
# `cmd` action lets a config execute arbitrary shell commands, which is not
# worth having in a process that reads every keystroke.
BINARY="kanata_linux_x64"

# Clean up the work dir on any exit (success, error, or interrupt)
trap 'rm -rf "$WORK_DIR"' EXIT

gh_parse_force_flag "$@"
gh_require_linux_x86_64
gh_require_cmds unzip dpkg

echo "Resolving latest kanata release..."
gh_resolve_latest jtroo/kanata
echo "Latest version:    $GH_VERSION"

# `kanata --version` prints a single "kanata <semver>" line.
INSTALLED=""
if command -v kanata >/dev/null 2>&1; then
    INSTALLED=$(kanata --version 2>/dev/null | head -n1 | awk '{print $2}')
fi
echo "Installed version: ${INSTALLED:-none}"

if gh_up_to_date "$INSTALLED" "$GH_VERSION"; then
    if ((FORCE == 0)); then
        echo ""
        echo "✓ kanata is already up to date."
        exit 0
    fi
    echo "Reinstalling anyway (--force)..."
fi

echo "Downloading kanata $GH_VERSION..."
gh_fetch_asset "linux-binaries-x64.zip" "$ARCHIVE"

echo "Extracting..."
if ! unzip -q -o "$ARCHIVE" "$BINARY" -d "$WORK_DIR"; then
    echo "Error: failed to extract $BINARY" >&2
    exit 1
fi
chmod +x "$WORK_DIR/$BINARY"

echo "Testing binary..."
if ! "$WORK_DIR/$BINARY" --version &>/dev/null; then
    echo "Error: extracted kanata is not working properly" >&2
    exit 1
fi

echo "Installing to $INSTALL_DIR (requires sudo)..."
if ! sudo install "$WORK_DIR/$BINARY" -D "$INSTALL_DIR/kanata"; then
    echo "Error: failed to install kanata to $INSTALL_DIR" >&2
    exit 1
fi

echo "✓ Successfully installed kanata!"
"$INSTALL_DIR/kanata" --version

echo ""
echo "Installation location: $INSTALL_DIR/kanata"
echo ""
echo "The binary alone does nothing. To finish the setup, see docs/kanata.md:"
echo "  1. just apply kanata          # link the config and the user service"
echo "  2. grant /dev/input + /dev/uinput access (group + udev rule)"
echo "  3. systemctl --user enable --now kanata.service"
