#!/usr/bin/env bash
# install-freecad.sh - Install or update FreeCAD (parametric 3D CAD) from the
# official Linux AppImage. Re-run anytime: it compares the recorded version
# against the latest stable release and only downloads when a newer one exists.
# --force reinstalls regardless.
#
# Installs entirely under $HOME (no sudo):
#   ~/.local/opt/freecad/FreeCAD.AppImage
#   ~/.local/opt/freecad/VERSION            what the AppImage above is
#   ~/.local/bin/freecad -> the AppImage above
#   ~/.local/share/applications/org.freecad.FreeCAD.desktop
#   ~/.local/share/icons/hicolor/<size>/apps/org.freecad.FreeCAD.png (4 sizes)
#
# Assumes: Linux x86_64, curl + jq + sha256sum + awk + dpkg, network, and the
# AppImage runtime (libfuse2t64 on Pop!_OS/Ubuntu 24.04 -- without it the app
# reports a FUSE error at launch). dpkg is used only for `--compare-versions`.
#
# The asset is ~820 MB, and the new one is downloaded alongside the old, so
# expect ~1.7 GB of transient space in ~/.local/opt/freecad.

set -euo pipefail # Exit on error, unset vars, and pipe failures

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/lib/github-release.sh
source "$SCRIPT_DIR/lib/github-release.sh"

INSTALL_DIR="$HOME/.local/opt/freecad"
APPIMAGE="$INSTALL_DIR/FreeCAD.AppImage"
STAMP="$INSTALL_DIR/VERSION"
BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/freecad"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
APPS_DIR="$DATA_HOME/applications"
APP_ID="org.freecad.FreeCAD"
DESKTOP_FILE="$APPS_DIR/$APP_ID.desktop"
ICON_ROOT="$DATA_HOME/icons/hicolor"

TMP_APPIMAGE=""
EXTRACT_DIR=""

cleanup() {
    [ -z "$TMP_APPIMAGE" ] || rm -f "$TMP_APPIMAGE"
    [ -z "$EXTRACT_DIR" ] || rm -rf "$EXTRACT_DIR"
}
trap cleanup EXIT

gh_parse_force_flag "$@"
gh_require_linux_x86_64
gh_require_cmds dpkg

# /releases/latest is the stable release specifically. FreeCAD also publishes a
# `weekly-*` prerelease that is usually newer by tag date -- resolving by date
# instead would silently put development builds on the machine.
echo "Resolving latest stable FreeCAD release..."
gh_resolve_latest FreeCAD/FreeCAD
echo "Latest version:    $GH_VERSION"

# The version comes from a stamp file rather than `FreeCAD.AppImage --version`,
# which would mount the 820 MB image through FUSE and boot enough of the app to
# print a string. The stamp is only trusted when the AppImage it describes is
# actually present, and --force ignores it either way.
INSTALLED=""
if [[ -f "$APPIMAGE" && -f "$STAMP" ]]; then
    INSTALLED=$(head -n1 "$STAMP" | tr -d '[:space:]')
fi
echo "Installed version: ${INSTALLED:-none}"

if gh_up_to_date "$INSTALLED" "$GH_VERSION"; then
    if ((FORCE == 0)); then
        echo ""
        echo "✓ FreeCAD is already up to date."
        exit 0
    fi
    echo "Reinstalling anyway (--force)..."
fi

# Downloaded into the install dir (not TMPDIR) so the final mv is an atomic
# rename on one filesystem, and so 820 MB never lands in a tmpfs.
mkdir -p "$INSTALL_DIR"
TMP_APPIMAGE=$(mktemp "$INSTALL_DIR/.FreeCAD.XXXXXX.AppImage")

# Matched on shape, not on the exact name: the name carries both the version
# and the Python ABI it was built against (`...-py311.AppImage`), and the ABI
# moves on its own schedule. The predicate still selects exactly one asset --
# it excludes aarch64, the `.zsync` delta file, and the `-SHA256.txt` sidecars,
# and gh_fetch_asset_matching fails loudly if that ever stops being true.
echo "Downloading the FreeCAD $GH_VERSION AppImage (~820 MB)..."
gh_fetch_asset_matching \
    'startswith("FreeCAD_") and contains("Linux-x86_64") and endswith(".AppImage")' \
    "$TMP_APPIMAGE"

chmod 0755 "$TMP_APPIMAGE"

# Extract the icons without launching the application. AppImages support this
# directly and do not need FUSE for it. Two things about the pattern:
#
#   - Unfiltered, --appimage-extract would unpack the whole ~2 GB AppDir.
#   - It names the app id rather than globbing *.png, because the AppDir also
#     bundles GTK's demo icons (gtk3-demo.png is a 256x256 that outweighs
#     FreeCAD's largest at 64x64). Picking "the biggest PNG under apps/" would
#     eventually ship the wrong artwork.
#
# Every bundled size is installed, so the theme can pick per context instead of
# scaling one file. Icon failure is non-fatal -- the launcher falls back to a
# generic icon.
EXTRACT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/freecad-extract.XXXXXX")
echo "Extracting the launcher icons..."
ICON_COUNT=0
if (cd "$EXTRACT_DIR" && "$TMP_APPIMAGE" --appimage-extract \
    "usr/share/icons/hicolor/*/apps/$APP_ID.png" >/dev/null 2>&1); then
    BUNDLED_ICONS="$EXTRACT_DIR/squashfs-root/usr/share/icons/hicolor"
    while IFS= read -r icon; do
        # The size comes from the directory the icon was bundled under, so the
        # theme is never told a 48x48 PNG is something else.
        size="${icon#"$BUNDLED_ICONS"/}"
        size="${size%%/*}"
        [[ "$size" =~ ^[0-9]+x[0-9]+$ ]] || continue
        mkdir -p "$ICON_ROOT/$size/apps"
        install -m 0644 "$icon" "$ICON_ROOT/$size/apps/$APP_ID.png"
        ICON_COUNT=$((ICON_COUNT + 1))
    done < <(find "$BUNDLED_ICONS" -type f -name "$APP_ID.png" 2>/dev/null)
fi
if ((ICON_COUNT == 0)); then
    echo "Warning: could not extract any bundled launcher icon"
fi

echo "Installing AppImage to $APPIMAGE..."
mv -f "$TMP_APPIMAGE" "$APPIMAGE"
TMP_APPIMAGE=""

# Written only after the mv, so an interrupted download never leaves a stamp
# claiming a version that is not on disk.
printf '%s\n' "$GH_VERSION" >"$STAMP"

mkdir -p "$BIN_DIR"
ln -sfn "$APPIMAGE" "$BIN"

# Modeled on the entry FreeCAD bundles inside the AppImage, with three
# deliberate differences: Exec points at the installed path instead of AppRun,
# the translated Comment/GenericName lines are dropped, and Categories names a
# single main category (upstream lists Graphics, Science, and Education, which
# can put the app in three menus). --single-instance is upstream's flag and is
# accepted when passed to the AppImage directly. The MimeType list is copied
# verbatim so "Open With" offers FreeCAD for the formats it reads.
mkdir -p "$APPS_DIR"
printf '%s\n' \
    '[Desktop Entry]' \
    'Type=Application' \
    'Name=FreeCAD' \
    'GenericName=CAD Application' \
    'Comment=Feature based parametric 3D modeler' \
    "Exec=\"$APPIMAGE\" --single-instance %F" \
    "TryExec=$APPIMAGE" \
    "Icon=$APP_ID" \
    'Terminal=false' \
    'StartupNotify=true' \
    'Categories=Graphics;3DGraphics;Engineering;' \
    'StartupWMClass=FreeCAD' \
    'MimeType=application/x-extension-fcstd;model/obj;image/vnd.dwg;image/vnd.dxf;model/vnd.collada+xml;application/iges;model/iges;model/step;model/step+zip;model/stl;application/vnd.shp;model/vrml;' \
    >"$DESKTOP_FILE"
chmod 0644 "$DESKTOP_FILE"

# Refresh desktop/icon caches when the utilities are available. Most desktop
# environments discover these files without an explicit refresh as well.
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPS_DIR" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$ICON_ROOT" 2>/dev/null || true
fi

echo ""
echo "✓ Successfully installed FreeCAD $GH_VERSION"
echo ""
echo "AppImage:     $APPIMAGE"
echo "PATH command: $BIN"
echo "Desktop file: $DESKTOP_FILE"
echo ""
echo "Launch it from the application launcher or run: freecad"
echo "If it reports a FUSE error, install libfuse2t64 (Pop!_OS/Ubuntu 24.04)."
