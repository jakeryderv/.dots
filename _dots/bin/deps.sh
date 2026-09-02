#!/usr/bin/env bash
# deps.sh - report which tools this repo expects and which are present.
#
# Required tools are needed to deploy and validate the repo itself. Optional
# ones are what individual packages configure; a missing optional tool means
# that package's config is deployed but unused, which is fine.

set -euo pipefail

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    BOLD=$'\033[1m' GREEN=$'\033[32m' YELLOW=$'\033[33m' RESET=$'\033[0m'
else
    BOLD='' GREEN='' YELLOW='' RESET=''
fi

ok() { printf '%s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s!%s %s\n' "$YELLOW" "$RESET" "$*"; }

required=(bash git just python3 find sed awk grep diff readlink file)
optional=(
    shellcheck shfmt stylua prettierd eslint_d ruff luac fc-cache
    starship vim nvim tmux fzf bat batcat rg fd fdfind ast-grep delta lazygit glow llm
    git gh just direnv uv node npm pnpm yarn tldr
    kanata pi claude agy cf wrangler herdr nix
)

missing=0

printf '%sRequired:%s\n' "$BOLD" "$RESET"
for cmd in "${required[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        ok "$cmd: $(command -v "$cmd")"
    else
        warn "$cmd missing"
        missing=1
    fi
done

printf '\n%sOptional / package-specific:%s\n' "$BOLD" "$RESET"
for cmd in "${optional[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        ok "$cmd: $(command -v "$cmd")"
    else
        warn "$cmd missing"
    fi
done

exit "$missing"
