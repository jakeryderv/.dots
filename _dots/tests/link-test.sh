#!/usr/bin/env bash
# Behaviour tests for _dots/bin/link.sh, run against a throwaway fixture repo.
#
# link.sh resolves its repo root from its own location and reads $HOME for
# targets, so the fixture places a copy at <fixture>/_dots/bin/link.sh and the
# tests run with HOME pointed at a scratch directory.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LINK_SOURCE="$REPO_ROOT/_dots/bin/link.sh"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fixture="$TEST_ROOT/repo"
target="$TEST_ROOT/home"
mkdir -p "$fixture/_dots/bin" "$fixture/config/alpha" "$fixture/config/beta/nested" \
    "$fixture/home" "$fixture/bin" "$target"
cp "$LINK_SOURCE" "$fixture/_dots/bin/link.sh"

printf 'alpha\n' >"$fixture/config/alpha/alpha.conf"
printf 'beta\n' >"$fixture/config/beta/beta.conf"
printf 'nested\n' >"$fixture/config/beta/nested/deep.conf"
printf '[user]\n\tname = fixture\n' >"$fixture/home/gitconfig"
printf '#!/bin/sh\n' >"$fixture/bin/tool"

cat >"$fixture/manifest" <<'EOF'
# PKG   MODE   SOURCE               TARGET
alpha   link   config/alpha         $XDG_CONFIG_HOME/alpha
beta    tree   config/beta          $XDG_CONFIG_HOME/beta
gitcfg  link   home/gitconfig       $HOME/.gitconfig
tools   tree   bin                  $HOME/.local/bin
EOF

git -C "$fixture" init -q
git -C "$fixture" add -A
git -C "$fixture" -c user.email=t@t -c user.name=t commit -qm init
# Created after the commit and never added, so the git ls-files enumerator must
# skip it. This is the property that makes .gitignore the only ignore list.
printf 'untracked\n' >"$fixture/config/beta/untracked.conf"

run_link() {
    env HOME="$target" XDG_CONFIG_HOME="$target/.config" XDG_DATA_HOME="$target/.local/share" \
        bash "$fixture/_dots/bin/link.sh" "$@"
}

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

expect_rc() {
    local expected="$1" name="$2"
    shift 2
    local output rc
    set +e
    output="$("$@" 2>&1)"
    rc=$?
    set -e
    [[ "$rc" -eq "$expected" ]] || fail "$name (expected rc=$expected, got rc=$rc)
$output"
    printf '%s' "$output"
}

# --- plan is a dry run -------------------------------------------------------
run_link plan >/dev/null
[[ ! -e "$target/.config/alpha" ]] || fail 'plan created links (should be a dry run)'

# --- status reports everything missing before apply --------------------------
output="$(expect_rc 1 'status before apply' run_link status)"
[[ "$output" == *'4 problem(s)'* ]] || fail "status did not report 4 missing rows
$output"

# --- apply ------------------------------------------------------------------
run_link apply >/dev/null
run_link status >/dev/null || fail 'status not clean after apply'

# link mode: one symlink at the target
[[ -L "$target/.config/alpha" ]] || fail 'link mode did not create a directory symlink'
[[ "$(readlink "$target/.config/alpha")" == "$fixture/config/alpha" ]] ||
    fail 'link mode symlink points at the wrong source'

# tree mode: real directories, one symlink per tracked file
[[ -d "$target/.config/beta" && ! -L "$target/.config/beta" ]] ||
    fail 'tree mode should leave the target directory real'
[[ -L "$target/.config/beta/beta.conf" ]] || fail 'tree mode did not link a tracked file'
[[ -L "$target/.config/beta/nested/deep.conf" ]] || fail 'tree mode did not recurse'

# The git ls-files enumerator is what keeps .gitignore the only ignore list.
[[ ! -e "$target/.config/beta/untracked.conf" ]] || fail 'untracked file was deployed'

# single-file link row, and a tree row into a shared directory
[[ "$(readlink "$target/.gitconfig")" == "$fixture/home/gitconfig" ]] ||
    fail 'single-file link row did not deploy'
[[ -L "$target/.local/bin/tool" ]] || fail 'tree row into ~/.local/bin did not deploy'

# --- apply is idempotent -----------------------------------------------------
output="$(run_link apply)"
[[ "$output" == *'0 conflict(s)'* ]] || fail "second apply reported conflicts
$output"
run_link status >/dev/null || fail 'status not clean after second apply'

# --- package filter uses the PKG column, not the path ------------------------
output="$(run_link plan alpha)"
[[ "$output" != *'beta'* ]] || fail 'package filter leaked another package'
output="$(run_link plan nosuchpkg)"
[[ "$output" == *'0 link(s) in scope'* ]] || fail 'unknown package should match no rows'

# --- diff is quiet when everything resolves ----------------------------------
run_link diff >/dev/null || fail 'diff reported differences on a clean tree'

# --- a real file at the target is a conflict, never clobbered ----------------
rm "$target/.gitconfig"
printf 'pre-existing\n' >"$target/.gitconfig"
output="$(expect_rc 1 'apply refuses to clobber' run_link apply gitcfg)"
[[ "$output" == *'CONFLICT'* ]] || fail "expected a CONFLICT report
$output"
[[ "$(head -1 "$target/.gitconfig")" == 'pre-existing' ]] || fail 'apply overwrote a real file'
rm "$target/.gitconfig"
run_link apply gitcfg >/dev/null

# --- unlink removes only links that resolve into the repo --------------------
ln -s /etc/hostname "$target/.local/bin/foreign"
run_link unlink >/dev/null
[[ ! -e "$target/.config/alpha" ]] || fail 'unlink left a link mode target behind'
[[ ! -e "$target/.config/beta/beta.conf" ]] || fail 'unlink left a tree mode link behind'
[[ -L "$target/.local/bin/foreign" ]] || fail 'unlink removed a foreign symlink'

echo 'link tests passed'
