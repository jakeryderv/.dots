#!/usr/bin/env bash
# install-tealdeer.sh - Install or update tealdeer (fast tldr-pages client).
# Re-run anytime: it compares the installed binary against the latest release
# and only downloads when a newer one exists. --force reinstalls regardless.
# Assumes: Linux x86_64 (sudo), curl + jq + sha256sum + awk + dpkg, network.
# dpkg is used only for `--compare-versions`; upstream ships no .deb.
# Installs the static musl release binary as `tldr` after verifying GitHub's
# SHA-256 digest, plus the matching bash completion into the user's XDG dir.

set -euo pipefail # Exit on error, unset vars, and pipe failures

REPO="tealdeer-rs/tealdeer"
BINARY="tldr" # what upstream calls the command; the asset is named `tealdeer-*`
ASSET_NAME="tealdeer-linux-x86_64-musl"
COMPLETION_ASSET="completions_bash"
INSTALL_DIR="/usr/local/bin"
COMPLETION_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/tealdeer-install.XXXXXX")"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || printf '%s\n' "${SCRIPT_DIR%/*}")"

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

for command in curl jq sha256sum awk dpkg; do
    command -v "$command" >/dev/null 2>&1 || {
        echo "Error: required command '$command' was not found" >&2
        exit 1
    }
done

# Download an asset by name and check it against the digest GitHub publishes
# alongside it, so a corrupted or substituted file never reaches the install.
fetch_asset() {
    local name="$1" dest="$2" asset url digest expected actual
    asset=$(printf '%s' "$RELEASE_JSON" | jq -cer --arg name "$name" '
		[.assets[] | select(.name == $name)]
		| if length == 1 then .[0] else error("expected exactly one matching asset") end
	')
    url=$(printf '%s' "$asset" | jq -er '.browser_download_url')
    digest=$(printf '%s' "$asset" | jq -er '.digest')
    [[ "$digest" =~ ^sha256:([0-9a-fA-F]{64})$ ]] || {
        echo "Error: invalid SHA-256 digest for $name" >&2
        exit 1
    }
    expected="${BASH_REMATCH[1],,}"

    if ! curl -fL --retry 3 -o "$dest" "$url"; then
        echo "Error: failed to download $name" >&2
        exit 1
    fi

    actual=$(sha256sum "$dest" | awk '{print $1}')
    if [[ "$actual" != "$expected" ]]; then
        echo "Error: SHA-256 verification failed for $name" >&2
        exit 1
    fi
    echo "Verified SHA-256: $actual ($name)"
}

echo "Resolving latest tealdeer release..."
RELEASE_JSON=$(curl -fsSL --retry 3 "https://api.github.com/repos/$REPO/releases/latest")
VERSION=$(printf '%s' "$RELEASE_JSON" | jq -er '.tag_name | ltrimstr("v")')
echo "Latest version:    $VERSION"

# `tldr` is a generic command name with several implementations, so only trust
# the version string when the binary actually identifies itself as tealdeer.
INSTALLED=""
if command -v "$BINARY" >/dev/null 2>&1; then
    VERSION_LINE=$("$BINARY" --version 2>/dev/null | head -n1 || true)
    if [[ "$VERSION_LINE" == "tealdeer "* ]]; then
        INSTALLED="${VERSION_LINE#tealdeer }"
    else
        echo "Note: existing '$BINARY' at $(command -v "$BINARY") is not tealdeer:"
        echo "      ${VERSION_LINE:-<no version output>}"
    fi
fi
echo "Installed version: ${INSTALLED:-none}"

# dpkg does the version comparison so upstream's scheme is honored rather than
# a string compare, which would call 1.9.0 older than 1.10.0.
NEED_BINARY=1
if [[ -n "$INSTALLED" ]] && dpkg --compare-versions "$INSTALLED" ge "$VERSION"; then
    NEED_BINARY=0
fi

# Tracked separately from the binary: the completion can go missing on its own
# (a re-apply, a manual cleanup) while the binary is perfectly current, and that
# case should self-heal instead of requiring --force.
NEED_COMPLETION=1
[[ -f "$COMPLETION_DIR/$BINARY" ]] && NEED_COMPLETION=0

# The completions directory is a `tree` row in the manifest precisely so it
# stays a real directory that third-party installers can write into. If it is
# ever a symlink into the repo, installing through it would commit tealdeer's
# completion as a tracked file -- so refuse and name the fix instead.
COMPLETION_TARGET="$(readlink -f "$COMPLETION_DIR")"
if [[ "$COMPLETION_TARGET" == "$REPO_ROOT"/* ]]; then
    echo ""
    echo "Warning: $COMPLETION_DIR resolves into the dotfiles repo:"
    echo "         $COMPLETION_TARGET"
    echo "         Installing there would commit tealdeer's completion as a tracked file."
    echo "         The scripts rows must be MODE=tree in the manifest; check with:  dots status scripts"
    echo "         Skipping the completion for now."
    NEED_COMPLETION=0
    SKIPPED_COMPLETION=1
fi

if ((FORCE)); then
    if ((NEED_BINARY == 0)); then
        echo "Reinstalling anyway (--force)..."
    fi
    NEED_BINARY=1
    ((${SKIPPED_COMPLETION:-0})) || NEED_COMPLETION=1
fi

if ((NEED_BINARY == 0 && NEED_COMPLETION == 0)); then
    echo ""
    echo "✓ tealdeer is already up to date."
    exit 0
fi

if ((NEED_BINARY)); then
    # Downloaded under the final command name so the install step needs no rename.
    echo "Downloading tealdeer $VERSION..."
    fetch_asset "$ASSET_NAME" "$WORK_DIR/$BINARY"
    chmod +x "$WORK_DIR/$BINARY"

    echo "Testing binary..."
    if ! "$WORK_DIR/$BINARY" --version >/dev/null 2>&1; then
        echo "Error: downloaded tealdeer is not working properly" >&2
        exit 1
    fi

    echo "Installing to $INSTALL_DIR (requires sudo)..."
    if ! sudo install "$WORK_DIR/$BINARY" -D -t "$INSTALL_DIR"; then
        echo "Error: failed to install tealdeer to $INSTALL_DIR" >&2
        exit 1
    fi
    hash -r 2>/dev/null || true
fi

if ((NEED_COMPLETION)); then
    # bash-completion loads on demand from the XDG data dir, so the file only
    # has to be named after the command. No shell rc changes are needed.
    echo "Installing bash completion to $COMPLETION_DIR..."
    fetch_asset "$COMPLETION_ASSET" "$WORK_DIR/completion"
    mkdir -p "$COMPLETION_DIR"
    install -m 0644 "$WORK_DIR/completion" "$COMPLETION_DIR/$BINARY"
fi

echo ""
echo "✓ tealdeer is installed."
"$INSTALL_DIR/$BINARY" --version

RESOLVED="$(command -v "$BINARY" || true)"
if [[ "$RESOLVED" != "$INSTALL_DIR/$BINARY" ]]; then
    echo ""
    echo "Warning: '$BINARY' on PATH resolves to ${RESOLVED:-nothing}, not $INSTALL_DIR/$BINARY."
    echo "         Another tldr client is shadowing this one (apt ships tealdeer as"
    echo "         /usr/bin/tldr). Remove it, or put $INSTALL_DIR earlier in PATH."
fi

echo ""
echo "Installation location: $INSTALL_DIR/$BINARY"
if ((${SKIPPED_COMPLETION:-0} == 0)); then
    echo "Bash completion:       $COMPLETION_DIR/$BINARY (new shells pick it up)"
fi
echo ""
echo "The page cache starts empty. Populate it before first use:"
echo ""
echo "    tldr --update"
echo ""
echo "Optional: the tealdeer package tracks ~/.config/tealdeer/config.toml,"
echo "which enables background cache refresh. Styles are left to tealdeer's"
echo "named-color defaults so output follows the terminal palette (carbonfox)."
