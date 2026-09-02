#!/usr/bin/env bash
# Portable repository validation. Unlike `just doctor`, this does not inspect
# the caller's shell wiring or live dotfile targets, so it is safe to run in CI.
# Requires python3 >= 3.11 (tomllib) for the config-parsing step.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# The manifest drives deployment, so a typo in it is a silent no-op at apply
# time: a SOURCE that does not exist simply contributes zero files. Validate it
# here, where the failure is loud and does not require a deployed machine.
echo 'Validating manifest...'
manifest_errors=0
while read -r pkg mode src dst _; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    case "$mode" in
    link | tree) ;;
    *)
        echo "error: unknown mode '$mode' for package '$pkg'" >&2
        manifest_errors=1
        ;;
    esac
    if [[ ! -e "$src" ]]; then
        echo "error: manifest source does not exist: $src (package '$pkg')" >&2
        manifest_errors=1
    elif [[ -z "$(git ls-files -- "$src")" ]]; then
        echo "error: manifest source has no tracked files: $src (package '$pkg')" >&2
        manifest_errors=1
    fi
    # These are literal manifest prefixes, not shell variables.
    # shellcheck disable=SC2016
    case "$dst" in
    '$HOME'/* | '$XDG_CONFIG_HOME'/* | '$XDG_DATA_HOME'/*) ;;
    *)
        echo "error: target must start with \$HOME, \$XDG_CONFIG_HOME, or \$XDG_DATA_HOME: $dst" >&2
        manifest_errors=1
        ;;
    esac
done <manifest
if ((manifest_errors)); then
    exit 1
fi

echo 'Checking package documentation...'
bash _dots/checks/verify-readmes.sh >/dev/null

# Relative links between docs rot silently when files move -- the stow-to-
# manifest migration broke 29 of them in one commit. Nothing renders this repo's
# markdown, so a broken link is invisible until someone follows it.
echo 'Checking documentation links...'
python3 - <<'PY'
import pathlib, re, subprocess, sys

broken = []
tracked_markdown = subprocess.check_output(
    ['git', 'ls-files', '-z', '--', '*.md'], text=True
).split('\0')
for tracked_path in filter(None, tracked_markdown):
    path = pathlib.Path(tracked_path)
    for match in re.finditer(r'\[[^\]]*\]\(([^)#][^)]*)\)', path.read_text()):
        target = match.group(1)
        if target.startswith(('http://', 'https://', 'mailto:')):
            continue
        if not (path.parent / target.split('#')[0]).exists():
            broken.append(f'{path} -> {target}')

for entry in broken:
    print(f'error: broken doc link: {entry}', file=sys.stderr)
sys.exit(1 if broken else 0)
PY

BASH_PATHS=(
    shell
    tools
    bin
    config
    home
    data/bash-completion/completions
    _dots/bin
    _dots/checks
    _dots/tests
)

LUA_PATHS=(
    config/nvim
    config/wezterm
)

# `find` reports a missing path on stderr and keeps going, and these traversals
# feed process substitutions whose exit status is discarded -- so a stale entry
# here would silently shrink the lint surface instead of failing. Check first.
for path in "${BASH_PATHS[@]}" "${LUA_PATHS[@]}"; do
    if [[ ! -e "$path" ]]; then
        echo "error: path list entry does not exist: $path" >&2
        exit 1
    fi
done

# Completion files are sourced, not executed, so they carry no shebang and
# declare their shell with a ShellCheck directive instead. Accept either marker.
is_bash_file() {
    head -n 1 "$1" | grep -Eq '^#!.*\bbash\b|^# shellcheck shell=bash$'
}

echo 'Checking Bash syntax...'
while IFS= read -r -d '' file; do
    if is_bash_file "$file"; then
        bash -n "$file"
    fi
done < <(find "${BASH_PATHS[@]}" -path '*/node_modules' -prune -o -type f ! -name local.sh -print0)

if command -v shellcheck >/dev/null 2>&1; then
    echo 'Running ShellCheck...'
    while IFS= read -r -d '' file; do
        if is_bash_file "$file"; then
            shellcheck -x -S warning "$file"
        fi
    done < <(find "${BASH_PATHS[@]}" -path '*/node_modules' -prune -o -type f ! -name local.sh -print0)
elif [[ "${REQUIRE_LINTERS:-0}" == 1 ]]; then
    echo 'error: shellcheck is required but unavailable' >&2
    exit 1
else
    echo 'Skipping ShellCheck (not installed).'
fi

# Formatting drift. shfmt takes no flags on purpose: with none it reads
# .editorconfig, which is what Neovim's format-on-save uses, so this checks the
# same rules the editor applies. Passing -i or similar would make shfmt ignore
# .editorconfig and silently diverge from the editor.
if command -v shfmt >/dev/null 2>&1; then
    echo 'Checking Bash formatting...'
    unformatted=0
    while IFS= read -r -d '' file; do
        is_bash_file "$file" || continue
        if ! shfmt --diff "$file"; then
            unformatted=$((unformatted + 1))
        fi
    done < <(find "${BASH_PATHS[@]}" -path '*/node_modules' -prune -o -type f ! -name local.sh -print0)
    if ((unformatted > 0)); then
        echo "error: $unformatted file(s) are not shfmt-formatted; run: shfmt -w <file>" >&2
        exit 1
    fi
elif [[ "${REQUIRE_LINTERS:-0}" == 1 ]]; then
    echo 'error: shfmt is required but unavailable' >&2
    exit 1
else
    echo 'Skipping Bash formatting check (shfmt not installed).'
fi

echo 'Parsing JSON and TOML configuration...'
python3 - <<'PY'
import json
import pathlib
import tomllib

root = pathlib.Path('.')
for path in root.rglob('*.json'):
    if not any(part in {'.git', 'node_modules'} for part in path.parts):
        json.loads(path.read_text())
for path in root.rglob('*.toml'):
    with path.open('rb') as stream:
        tomllib.load(stream)
PY

if command -v luac >/dev/null 2>&1; then
    echo 'Checking Lua syntax...'
    while IFS= read -r -d '' file; do
        luac -p "$file"
    done < <(find "${LUA_PATHS[@]}" -path '*/node_modules' -prune -o -type f -name '*.lua' -print0)
elif [[ "${REQUIRE_LINTERS:-0}" == 1 ]]; then
    echo 'error: luac is required but unavailable' >&2
    exit 1
else
    echo 'Skipping Lua syntax check (luac not installed).'
fi

# Lua was the last language whose formatter ran only on save. shfmt has gated
# Bash here for a while; stylua now gates Lua the same way, so the editor and
# this check run the same pinned binary from flake.nix. config/nvim has its own
# .stylua.toml; config/wezterm falls back to .editorconfig. Blocks that are
# aligned or grouped by hand carry `-- stylua: ignore`.
if command -v stylua >/dev/null 2>&1; then
    echo 'Checking Lua formatting...'
    stylua --check "${LUA_PATHS[@]}"
elif [[ "${REQUIRE_LINTERS:-0}" == 1 ]]; then
    echo 'error: stylua is required but unavailable' >&2
    exit 1
else
    echo 'Skipping Lua formatting check (stylua not installed).'
fi

# A kanata config that does not parse leaves the keyboard unmapped, and the
# failure only shows up when the service restarts -- by which point typing may
# be how you would fix it. `--check` parses and exits without touching any
# device, so it is safe to run anywhere.
#
# Unlike the linters above this is never escalated by REQUIRE_LINTERS: kanata is
# package-specific software rather than a repo-wide tool. CI does pull it from
# the flake's nixpkgs (see .github/workflows/ci.yml), so the check runs there
# too, but a local machine without the package still passes the gate.
if command -v kanata >/dev/null 2>&1; then
    echo 'Checking kanata configuration...'
    kanata --cfg config/kanata/kanata.kbd --check >/dev/null
else
    echo 'Skipping kanata config check (kanata not installed).'
fi

echo 'Running behavior tests...'
bash _dots/tests/run.sh

echo 'Repository checks passed.'
