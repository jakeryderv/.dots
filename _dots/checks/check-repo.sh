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
import pathlib, re, sys

broken = []
for path in pathlib.Path('.').rglob('*.md'):
    if '.git/' in str(path):
        continue
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

echo 'Checking shared agent skills...'
bash _dots/checks/verify-agent-skills.sh

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

# Vendored content: tracked here but authored upstream. Linted like everything
# else, but never reformatted -- rewriting it would widen the diff against the
# source it was forked from and make the next re-sync harder. See
# docs/agent-skills.md for provenance.
NO_REFORMAT=(
    home/agent-skills
)

LUA_PATHS=(
    config/nvim
    config/wezterm
)

# `find` reports a missing path on stderr and keeps going, and these traversals
# feed process substitutions whose exit status is discarded -- so a stale entry
# here would silently shrink the lint surface instead of failing. Check first.
for path in "${BASH_PATHS[@]}" "${LUA_PATHS[@]}" "${NO_REFORMAT[@]}"; do
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
done < <(find "${BASH_PATHS[@]}" -type f ! -name local.sh -print0)

if command -v shellcheck >/dev/null 2>&1; then
    echo 'Running ShellCheck...'
    while IFS= read -r -d '' file; do
        if is_bash_file "$file"; then
            shellcheck -x -S warning "$file"
        fi
    done < <(find "${BASH_PATHS[@]}" -type f ! -name local.sh -print0)
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
        skip=0
        for vendored in "${NO_REFORMAT[@]}"; do
            [[ "$file" == "$vendored"/* ]] && skip=1
        done
        ((skip)) && continue
        if ! shfmt --diff "$file"; then
            unformatted=$((unformatted + 1))
        fi
    done < <(find "${BASH_PATHS[@]}" -type f ! -name local.sh -print0)
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

echo 'Parsing JSON, TOML, and Python configuration...'
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
python_config = root / 'config/qutebrowser/config.py'
compile(python_config.read_text(), str(python_config), 'exec')
PY

if command -v luac >/dev/null 2>&1; then
    echo 'Checking Lua syntax...'
    while IFS= read -r -d '' file; do
        luac -p "$file"
    done < <(find "${LUA_PATHS[@]}" -type f -name '*.lua' -print0)
elif [[ "${REQUIRE_LINTERS:-0}" == 1 ]]; then
    echo 'error: luac is required but unavailable' >&2
    exit 1
else
    echo 'Skipping Lua syntax check (luac not installed).'
fi

echo 'Running behavior tests...'
bash _dots/tests/run.sh

echo 'Repository checks passed.'
