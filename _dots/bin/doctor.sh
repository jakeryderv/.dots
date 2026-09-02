#!/usr/bin/env bash
# doctor.sh - health checks for this machine's dotfiles installation.
#
# Unlike _dots/checks/check-repo.sh, which validates the repository and is safe to
# run in CI, this inspects the caller's live environment: shell wiring, the
# deployed CLI entrypoint, and the state of the links the manifest declares.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    BOLD=$'\033[1m' GREEN=$'\033[32m' YELLOW=$'\033[33m' RESET=$'\033[0m'
else
    BOLD='' GREEN='' YELLOW='' RESET=''
fi

ok() { printf '%s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s!%s %s\n' "$YELLOW" "$RESET" "$*"; }

fail=0

printf '%sDotfiles doctor%s\n\n' "$BOLD" "$RESET"

if [[ -z "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
    ok "git working tree clean"
else
    warn "git working tree has changes"
fi

if command -v just >/dev/null 2>&1; then
    ok "just: $(command -v just)"
else
    warn "just is not installed; it comes from flake.nix: nix profile add ~/.dots"
    fail=1
fi

# The `dots` entrypoint is itself a deployed script now, not a special-cased
# symlink, so this is really a spot check that the scripts rows applied.
expected_dots="$REPO_ROOT/pkgs/scripts/dots"
actual_dots="$(readlink -f "$HOME/.local/bin/dots" 2>/dev/null || true)"
if [[ "$actual_dots" == "$(readlink -f "$expected_dots")" ]]; then
    ok "\$HOME/.local/bin/dots points at pkgs/scripts/dots"
else
    warn "\$HOME/.local/bin/dots is not linked to pkgs/scripts/dots; run: just apply scripts"
    fail=1
fi

if grep -q '\.dots/shell/_init_\.sh' "$HOME/.bashrc" 2>/dev/null; then
    ok "\$HOME/.bashrc sources shell/_init_.sh"
else
    warn "\$HOME/.bashrc does not appear to source shell/_init_.sh"
    fail=1
fi

if [[ -f "$REPO_ROOT/shell/local.sh" ]]; then
    ok "shell/local.sh exists"
else
    warn "shell/local.sh missing; copy shell/local.sh.example"
fi

# kanata is only useful when all three of these line up: the binary exists, the
# user can reach the input devices, and the service is actually running. Each
# fails independently and none of them are visible from the config alone.
if command -v kanata >/dev/null 2>&1; then
    if id -nG | tr ' ' '\n' | grep -qx input; then
        ok "user is in the input group"
    else
        warn "user is not in the input group; see docs/kanata.md (needs re-login)"
        fail=1
    fi
    if systemctl --user is-active --quiet kanata.service; then
        ok "kanata.service is running"
    else
        warn "kanata.service is not running; start it: systemctl --user start kanata.service"
        fail=1
    fi
else
    warn "kanata unavailable; skipping keyboard remapper checks"
fi

# A flake package that another PATH entry provides first is installed but never
# run, which is silent: `nix profile list` and `just deps` both look healthy. It
# has happened twice -- a stale ~/.local/bin/uvx outranked the flake copy and
# broke `uvx` outright, and a hand-downloaded d2 kept resolving after the
# package was added. ~/.local/bin sits ahead of ~/.nix-profile/bin and cannot be
# reordered from this repo: Ubuntu's ~/.profile sources ~/.bashrc (and so
# shell/exports.sh) before making its own prepend, so it always wins. Detect it
# instead, and delete the older copy when it shows up.
shadowed=()
if [[ -d "$HOME/.nix-profile/bin" ]]; then
    for binary in "$HOME/.nix-profile/bin"/*; do
        [[ -x "$binary" && ! -d "$binary" ]] || continue
        name="${binary##*/}"
        resolved="$(command -v "$name" 2>/dev/null || true)"
        # Only a real path counts; builtins and keywords resolve to a bare word.
        [[ "$resolved" == /* && "$resolved" != "$binary" ]] || continue
        shadowed+=("$name: $resolved")
    done
fi
if ((${#shadowed[@]})); then
    warn "flake binaries shadowed by an earlier PATH entry (delete the older copy):"
    printf '    %s\n' "${shadowed[@]}"
    fail=1
else
    ok "no flake binary is shadowed on PATH"
fi

check_log="$(mktemp)"
status_log="$(mktemp)"
trap 'rm -f "$check_log" "$status_log"' EXIT

if bash "$REPO_ROOT/_dots/checks/check-repo.sh" >"$check_log" 2>&1; then
    ok "portable repository checks pass"
else
    warn "portable repository checks failed"
    cat "$check_log"
    fail=1
fi

if bash "$REPO_ROOT/_dots/bin/link.sh" status >"$status_log" 2>&1; then
    ok "all manifest rows resolve into the repo"
else
    warn "manifest rows report missing or conflicting targets"
    cat "$status_log"
    fail=1
fi

printf '\n'
if ((fail)); then
    warn "doctor found issues"
    exit 1
fi
ok "doctor passed"
