#!/usr/bin/env bash
# verify-readmes.sh - Enforce the repo's documentation conventions:
#
#   1. Every package named in the manifest has docs/<pkg>.md.
#   2. Every top-level directory has a README.md describing that tree, EXCEPT
#      directories that are themselves manifest sources.
#
# The exception in (2) is load-bearing, not a convenience. Files are enumerated
# with `git ls-files`, so anything tracked inside a source directory is deployed
# -- a README.md inside bin/ would land at ~/.local/bin/README.md. Source
# directories hold only deployable content; their documentation lives in docs/.
#
# Exits non-zero if anything is missing, so it can gate CI or a pre-commit hook.
#
# Assumes: run from anywhere; resolves the repo root as this script's parent dir.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$REPO_ROOT/manifest"

missing=()
ok=()

# (1) Every manifest package is documented.
while read -r pkg _; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    if [[ -f "$REPO_ROOT/docs/$pkg.md" ]]; then
        ok+=("docs/$pkg.md")
    else
        missing+=("docs/$pkg.md — no doc for manifest package '$pkg'")
    fi
done < <(sort -u -k1,1 "$MANIFEST")

# Directories that ARE a manifest source, and so must not contain a README of
# their own. Compared whole, not by leading path segment: `bin` is a source, but
# `config` merely contains sources (config/nvim, config/ghostty, ...) and must
# still describe itself.
mapfile -t sources < <(awk '!/^#/ && NF {print $3}' "$MANIFEST" | sort -u)

is_source() {
    local name="$1" s
    for s in "${sources[@]}"; do
        [[ "$s" == "$name" ]] && return 0
    done
    return 1
}

# (2) Every non-source top-level directory describes itself.
for dir in "$REPO_ROOT"/*/; do
    name="$(basename "$dir")"
    [[ "$name" == ".git" ]] && continue
    if is_source "$name"; then
        ok+=("$name/ (manifest source — README intentionally absent)")
        continue
    fi
    if [[ -f "$dir/README.md" ]]; then
        ok+=("$name/README.md")
    else
        missing+=("$name/README.md")
    fi
done

for name in "${ok[@]}"; do
    printf '  \033[1;32m✓\033[0m %s\n' "$name"
done

if ((${#missing[@]})); then
    echo
    for name in "${missing[@]}"; do
        printf '  \033[1;31m✗ %s\033[0m\n' "$name"
    done
    echo
    printf '\033[1;31m%d missing.\033[0m\n' "${#missing[@]}"
    exit 1
fi

echo
printf '\033[1;32mAll %d documentation targets present.\033[0m\n' "${#ok[@]}"
