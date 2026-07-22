#!/usr/bin/env bash
# Portable repository validation. Unlike `dots doctor`, this does not inspect
# the caller's shell wiring or live dotfile targets, so it is safe to run in CI.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo 'Checking package documentation...'
bash _helpers/verify-readmes.sh >/dev/null

echo 'Checking shared agent skills...'
bash _helpers/verify-agent-skills.sh

echo 'Checking Bash syntax...'
while IFS= read -r -d '' file; do
    if head -n 1 "$file" | grep -Eq '^#!.*\bbash\b'; then
        bash -n "$file"
    fi
done < <(find setup.sh _bash _helpers scripts/.local/bin _dots/bin _dots/tests \
    -type f ! -name local.sh -print0)

if command -v shellcheck >/dev/null 2>&1; then
    echo 'Running ShellCheck...'
    while IFS= read -r -d '' file; do
        if head -n 1 "$file" | grep -Eq '^#!.*\bbash\b'; then
            shellcheck -x -S warning "$file"
        fi
    done < <(find setup.sh _bash _helpers scripts/.local/bin _dots/bin _dots/tests \
        -type f ! -name local.sh -print0)
elif [[ "${REQUIRE_LINTERS:-0}" == 1 ]]; then
    echo 'error: shellcheck is required but unavailable' >&2
    exit 1
else
    echo 'Skipping ShellCheck (not installed).'
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
python_config = root / 'qutebrowser/.config/qutebrowser/config.py'
compile(python_config.read_text(), str(python_config), 'exec')
PY

if command -v luac >/dev/null 2>&1; then
    echo 'Checking Lua syntax...'
    while IFS= read -r -d '' file; do
        luac -p "$file"
    done < <(find nvim wezterm -type f -name '*.lua' -print0)
elif [[ "${REQUIRE_LINTERS:-0}" == 1 ]]; then
    echo 'error: luac is required but unavailable' >&2
    exit 1
else
    echo 'Skipping Lua syntax check (luac not installed).'
fi

echo 'Running behavior tests...'
bash _dots/tests/run.sh

echo 'Repository checks passed.'
