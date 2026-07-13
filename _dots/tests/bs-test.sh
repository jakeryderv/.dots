#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BS="$REPO_ROOT/scripts/.local/bin/bs"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

touch "$TEST_ROOT/a space.txt" "$TEST_ROOT/plain.txt"

# Stand in for fzf: select the NUL-delimited filename containing a space.
fzf() {
    local item
    while IFS= read -r -d '' item; do
        if [[ "$item" == *' '* ]]; then
            printf '%s\0' "$item"
            return
        fi
    done
}
export -f fzf

output="$("$BS" --fzf "$TEST_ROOT")"
[[ "$output" == "$TEST_ROOT/a space.txt" ]] || {
    printf 'FAIL: spaced filename was not preserved: %q\n' "$output" >&2
    exit 1
}

json="$("$BS" --json "$TEST_ROOT")"
python3 -c 'import json,sys; data=json.load(sys.stdin); assert len(data) == 2 and any(x["name"] == "a space.txt" for x in data)' <<<"$json"

echo 'bs tests passed'
