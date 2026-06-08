#!/usr/bin/env bash
# install-qutebrowser.sh - Install/update qutebrowser from source using the
# official scripts/mkvenv.py (newer Qt/QtWebEngine than Ubuntu's apt package),
# then install the .desktop entry + icons so it shows up in the app launcher.
#
# Re-run anytime to update: mkvenv.py --update does a `git pull`, rebuilds the
# venv, and runs a Qt smoke test. Any extra args are passed through to mkvenv.py
# (e.g. `--keep` to reuse the existing venv and skip the big Qt re-download).

set -euo pipefail  # Exit on error, unset vars, and pipe failures

REPO="https://github.com/qutebrowser/qutebrowser.git"
SRC="$HOME/.local/src/qutebrowser"          # git checkout + venv live here
BIN="$HOME/.local/bin/qutebrowser"          # symlink that ends up on your PATH
VENV_BIN="$SRC/.venv/bin/qutebrowser"       # what mkvenv.py builds
APPS="$HOME/.local/share/applications"      # XDG desktop entries (launcher scans this)
ICONS="$HOME/.local/share/icons/hicolor"    # XDG icon theme

# Clone on first run; mkvenv.py --update handles the `git pull` on later runs.
if [ ! -d "$SRC/.git" ]; then
    echo "Cloning qutebrowser into $SRC..."
    mkdir -p "$(dirname "$SRC")"
    if ! git clone "$REPO" "$SRC"; then
        echo "Error: failed to clone qutebrowser"
        exit 1
    fi
fi

# Build/update the venv. --update git-pulls first; the default run recreates the
# venv from scratch and runs a Qt smoke test, so a broken build fails loudly here
# before we touch the symlink or launcher entry.
echo "Building qutebrowser venv via mkvenv.py (this can take a while + downloads Qt)..."
if ! ( cd "$SRC" && python3 scripts/mkvenv.py --update "$@" ); then
    echo "Error: mkvenv.py failed to build the qutebrowser environment"
    exit 1
fi

echo "Linking $BIN -> $VENV_BIN..."
mkdir -p "$(dirname "$BIN")"
ln -sf "$VENV_BIN" "$BIN"

# --- Desktop entry + icons -------------------------------------------------
# The from-source method installs NO .desktop file, so the launcher can't find
# qutebrowser even though it's on PATH. Install the one shipped in the repo,
# rewriting Exec/TryExec to the absolute binary path so the launcher doesn't
# depend on ~/.local/bin being in its environment's PATH.
echo "Installing desktop entry + icons..."
mkdir -p "$APPS"
sed -E "s|^Exec=qutebrowser|Exec=$BIN|; s|^TryExec=.*|TryExec=$BIN|" \
    "$SRC/misc/org.qutebrowser.qutebrowser.desktop" \
    > "$APPS/org.qutebrowser.qutebrowser.desktop"

for png in "$SRC"/qutebrowser/icons/qutebrowser-*x*.png; do
    sz=$(basename "$png" | sed -E 's/qutebrowser-([0-9]+)x[0-9]+\.png/\1/')
    dir="$ICONS/${sz}x${sz}/apps"
    mkdir -p "$dir"
    cp "$png" "$dir/qutebrowser.png"
done
mkdir -p "$ICONS/scalable/apps"
cp "$SRC/qutebrowser/icons/qutebrowser.svg" "$ICONS/scalable/apps/qutebrowser.svg"

# Refresh launcher + icon caches (best-effort; not all desktops need these).
update-desktop-database "$APPS" 2>/dev/null || true
gtk-update-icon-cache -f -t "$ICONS" 2>/dev/null || true

echo "✓ Successfully installed/updated qutebrowser!"
# --version prints an ASCII banner first, so grep the actual version line.
"$BIN" --version 2>/dev/null | grep -iE '^qutebrowser v[0-9]' || true

echo ""
echo "Source checkout: $SRC"
echo "Binary symlink:  $BIN"
echo "Desktop entry:   $APPS/org.qutebrowser.qutebrowser.desktop"
echo "Re-run this script to update. Add --keep to reuse the venv (skip Qt re-download)."
