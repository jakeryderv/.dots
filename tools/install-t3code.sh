#!/usr/bin/env bash
# install-t3code.sh - Install/update the latest official T3 Code AppImage and
# integrate it with the shell PATH and desktop application launcher.
#
# Installs entirely under $HOME (no sudo):
#   ~/.local/opt/t3code/T3-Code.AppImage
#   ~/.local/bin/t3code -> the AppImage above
#   ~/.local/share/applications/com.t3tools.t3code.desktop
#   ~/.local/share/icons/hicolor/512x512/apps/t3code.png
#
# T3 Code has its own AppImage updater, so this helper is mainly for first-time
# setup, restoring a machine, or forcing a clean update. It is safe to re-run.
#
# Assumes: Linux x86_64, curl, jq, sha256sum, and the AppImage runtime.
# On Pop!_OS/Ubuntu 24.04, install libfuse2t64 if the app reports a FUSE error.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/lib/github-release.sh
source "$SCRIPT_DIR/lib/github-release.sh"

INSTALL_DIR="$HOME/.local/opt/t3code"
APPIMAGE="$INSTALL_DIR/T3-Code.AppImage"
BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/t3code"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
APPS_DIR="$DATA_HOME/applications"
DESKTOP_FILE="$APPS_DIR/com.t3tools.t3code.desktop"
ICON_DIR="$DATA_HOME/icons/hicolor/512x512/apps"
ICON_FILE="$ICON_DIR/t3code.png"

TMP_APPIMAGE=""
EXTRACT_DIR=""

cleanup() {
    [ -z "$TMP_APPIMAGE" ] || rm -f "$TMP_APPIMAGE"
    [ -z "$EXTRACT_DIR" ] || rm -rf "$EXTRACT_DIR"
}
trap cleanup EXIT

gh_require_linux_x86_64
gh_require_cmds

echo "Checking the latest official T3 Code release..."
gh_resolve_latest pingdotgg/t3code
VERSION="$GH_TAG" # t3code tags are not v-prefixed

# Downloaded into the install dir (not TMPDIR) so the final mv is an atomic
# rename on one filesystem.
mkdir -p "$INSTALL_DIR"
TMP_APPIMAGE=$(mktemp "$INSTALL_DIR/.T3-Code.XXXXXX.AppImage")

echo "Downloading the $VERSION AppImage..."
gh_fetch_asset_matching 'endswith("-x86_64.AppImage")' "$TMP_APPIMAGE"

chmod 0755 "$TMP_APPIMAGE"

# Extract the icon without launching the application. AppImages support this
# directly and do not need FUSE for extraction. Icon failure is non-fatal: the
# application remains usable and the launcher will fall back to a generic icon.
EXTRACT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/t3code-extract.XXXXXX")
echo "Extracting the launcher icon..."
if (cd "$EXTRACT_DIR" && "$TMP_APPIMAGE" --appimage-extract >/dev/null 2>&1); then
    BUNDLED_ICONS="$EXTRACT_DIR/squashfs-root/usr/share/icons"
    ICON_SOURCE=""
    if [ -d "$BUNDLED_ICONS" ]; then
        ICON_SOURCE=$(find "$BUNDLED_ICONS" -type f -name '*.png' \
            -printf '%s\t%p\n' | sort -nr | sed -n '1s/^[^\t]*\t//p')
    fi
    if [ -n "$ICON_SOURCE" ]; then
        mkdir -p "$ICON_DIR"
        install -m 0644 "$ICON_SOURCE" "$ICON_FILE"
    else
        echo "Warning: no bundled PNG icon was found"
    fi
else
    echo "Warning: could not extract the bundled launcher icon"
fi

echo "Installing AppImage to $APPIMAGE..."
mv -f "$TMP_APPIMAGE" "$APPIMAGE"
TMP_APPIMAGE=""

mkdir -p "$BIN_DIR"
ln -sfn "$APPIMAGE" "$BIN"

mkdir -p "$APPS_DIR"
printf '%s\n' \
    '[Desktop Entry]' \
    'Type=Application' \
    'Name=T3 Code' \
    'Comment=Control plane for coding agents' \
    "Exec=\"$APPIMAGE\" %U" \
    "TryExec=$APPIMAGE" \
    'Icon=t3code' \
    'Terminal=false' \
    'Categories=Development;' \
    'StartupWMClass=t3code' \
    >"$DESKTOP_FILE"
chmod 0644 "$DESKTOP_FILE"

# Refresh desktop/icon caches when the utilities are available. Most desktop
# environments discover these files without an explicit refresh as well.
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPS_DIR" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$DATA_HOME/icons/hicolor" 2>/dev/null || true
fi

echo "✓ Successfully installed T3 Code $VERSION"
echo ""
echo "AppImage:     $APPIMAGE"
echo "PATH command: $BIN"
echo "Desktop file: $DESKTOP_FILE"
echo ""
echo "Launch it from the application launcher or run: t3code"
echo "T3 Code can handle routine AppImage updates from inside the app."
