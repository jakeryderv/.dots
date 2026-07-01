#!/usr/bin/env bash
# verify-readmes.sh - Ensure every package / asset dir in the dotfiles repo has
# its own README.md (the repo's "self-documenting package" convention).
#
# Checks every top-level directory except .git and prints a PASS/FAIL summary.
# Exits non-zero if any are missing, so it can gate CI or a pre-commit hook.
#
# Assumes: run from anywhere; resolves the repo root as this script's parent dir.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

missing=()
ok=()

for dir in "$REPO_ROOT"/*/; do
	name="$(basename "$dir")"
	[[ "$name" == ".git" ]] && continue
	if [[ -f "$dir/README.md" ]]; then
		ok+=("$name")
	else
		missing+=("$name")
	fi
done

for name in "${ok[@]}"; do
	printf '  \033[1;32m✓\033[0m %s\n' "$name"
done

if ((${#missing[@]})); then
	echo
	for name in "${missing[@]}"; do
		printf '  \033[1;31m✗ %s — missing README.md\033[0m\n' "$name"
	done
	echo
	printf '\033[1;31m%d dir(s) missing a README.\033[0m\n' "${#missing[@]}"
	exit 1
fi

echo
printf '\033[1;32mAll %d dirs have a README.\033[0m\n' "${#ok[@]}"
