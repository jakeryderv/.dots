#!/usr/bin/env bash
# install-qutebrowser.sh - Install/update qutebrowser from source using the
# official scripts/mkvenv.py (newer Qt/QtWebEngine than Ubuntu's apt package),
# then install the .desktop entry + icons so it shows up in the app launcher.
#
# Re-run anytime to update. By default this recreates the venv from scratch
# (downloads Qt, ~150 MB). Pass --keep to reuse the existing venv and just pull
# the latest code -- much faster, and the safer everyday update.
#
# Assumes: Linux (apt for desktop/icon integration), uv + git + python3, network.
#
# NOTE: we create the venv with `uv`, NOT mkvenv.py's own `python -m venv`. On
# this system `python3` is a uv-managed standalone CPython whose ensurepip can't
# bootstrap a venv, so `python -m venv` fails. uv sidesteps ensurepip entirely.

set -euo pipefail # Exit on error, unset vars, and pipe failures

REPO="https://github.com/qutebrowser/qutebrowser.git"
SRC="$HOME/.local/src/qutebrowser"       # git checkout + venv live here
BIN="$HOME/.local/bin/qutebrowser"       # symlink that ends up on your PATH
VENV="$SRC/.venv"                        # the virtualenv uv builds
VENV_BIN="$VENV/bin/qutebrowser"         # the launcher inside the venv
APPS="$HOME/.local/share/applications"   # XDG desktop entries (launcher scans this)
ICONS="$HOME/.local/share/icons/hicolor" # XDG icon theme
PYVER="3.12"                             # Python version uv provisions for the venv

# Clone on first run; mkvenv.py --update handles the `git pull` on later runs.
if [ ! -d "$SRC/.git" ]; then
    echo "Cloning qutebrowser into $SRC..."
    mkdir -p "$(dirname "$SRC")"
    if ! git clone "$REPO" "$SRC"; then
        echo "Error: failed to clone qutebrowser"
        exit 1
    fi
fi

# --keep reuses the existing venv (skip the Qt re-download); default recreates it.
KEEP=0
[ "${1:-}" = "--keep" ] && KEEP=1

if ! command -v uv >/dev/null 2>&1; then
    echo "Error: uv is required to build the venv but was not found on PATH"
    exit 1
fi

if [ "$KEEP" -eq 1 ]; then
    if [ ! -x "$VENV_BIN" ]; then
        echo "Error: --keep given but no usable venv at $VENV (run without --keep first)"
        exit 1
    fi
    echo "Reusing existing venv (--keep)..."
else
    echo "Creating fresh venv with uv (downloads Qt; takes a few minutes)..."
    rm -rf "$VENV"
    if ! uv venv "$VENV" --python "$PYVER" --seed; then
        echo "Error: failed to create venv with uv"
        exit 1
    fi
fi

# mkvenv.py --keep populates the (uv-created) venv: git pull via --update, install
# qutebrowser + PyQt/Qt, run a Qt smoke test, regenerate docs. A broken build fails
# loudly here, before we touch the symlink or launcher entry.
echo "Building qutebrowser into the venv via mkvenv.py..."
if ! (cd "$SRC" && python3 scripts/mkvenv.py --keep --update); then
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
    >"$APPS/org.qutebrowser.qutebrowser.desktop"

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
