#!/usr/bin/env bash
# doctor.sh - health checks for this machine's dotfiles installation.
#
# Unlike tools/check-repo.sh, which validates the repository and is safe to
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
    warn "just is not installed (sudo apt install just)"
    fail=1
fi

# The `dots` entrypoint is itself a deployed script now, not a special-cased
# symlink, so this is really a spot check that the scripts rows applied.
expected_dots="$REPO_ROOT/bin/dots"
actual_dots="$(readlink -f "$HOME/.local/bin/dots" 2>/dev/null || true)"
if [[ "$actual_dots" == "$(readlink -f "$expected_dots")" ]]; then
    ok "\$HOME/.local/bin/dots points at bin/dots"
else
    warn "\$HOME/.local/bin/dots is not linked to bin/dots; run: just apply scripts"
    fail=1
fi

if grep -q '\.dots/_bash/_init_\.sh' "$HOME/.bashrc" 2>/dev/null; then
    ok "\$HOME/.bashrc sources _bash/_init_.sh"
else
    warn "\$HOME/.bashrc does not appear to source _bash/_init_.sh"
    fail=1
fi

if [[ -f "$REPO_ROOT/_bash/local.sh" ]]; then
    ok "_bash/local.sh exists"
else
    warn "_bash/local.sh missing; copy _bash/local.sh.example"
fi

if command -v opencode >/dev/null 2>&1; then
    if opencode debug config >/dev/null 2>&1; then
        ok "opencode resolved config is valid"
    else
        warn "opencode config failed to load"
        fail=1
    fi
else
    warn "opencode unavailable; skipping resolved config validation"
fi

check_log="$(mktemp)"
status_log="$(mktemp)"
trap 'rm -f "$check_log" "$status_log"' EXIT

if bash "$REPO_ROOT/tools/check-repo.sh" >"$check_log" 2>&1; then
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
