#!/usr/bin/env bash
# Exercise live shared-skill verification against manifest tree topology: real
# canonical directories containing one symlink per tracked file.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERIFY="$REPO_ROOT/_dots/checks/verify-agent-skills.sh"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

home="$TEST_ROOT/home"
mkdir -p "$home/.agents/skills" "$home/.claude/skills"

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

expect_failure() {
    local name="$1"
    shift
    local output rc
    set +e
    output="$("$@" 2>&1)"
    rc=$?
    set -e
    ((rc != 0)) || fail "$name unexpectedly passed"
    printf '%s\n' "$output"
}

while IFS= read -r skill_dir; do
    skill="${skill_dir##*/}"
    source_rel="${skill_dir#"$REPO_ROOT"/}"
    live_dir="$home/.agents/skills/$skill"
    mkdir -p "$live_dir"

    while IFS= read -r tracked; do
        rel="${tracked#"$source_rel"/}"
        mkdir -p "$(dirname "$live_dir/$rel")"
        ln -s "$REPO_ROOT/$tracked" "$live_dir/$rel"
    done < <(git -C "$REPO_ROOT" ls-files -- "$source_rel")

    ln -s "$REPO_ROOT/home/agent-skills/claude/skills/$skill" "$home/.claude/skills/$skill"
done < <(find "$REPO_ROOT/home/agent-skills/agents/skills" -mindepth 1 -maxdepth 1 -type d -print | sort)

HOME="$home" bash "$VERIFY" --live >/dev/null || fail 'valid tree deployment did not pass'

skill=systematic-debugging
live_file="$home/.agents/skills/$skill/SKILL.md"
rm "$live_file"
cp "$REPO_ROOT/home/agent-skills/agents/skills/$skill/SKILL.md" "$live_file"
output="$(expect_failure 'real copied skill file' env HOME="$home" bash "$VERIFY" --live)"
[[ "$output" == *'does not resolve to the canonical source'* ]] ||
    fail "copied-file failure was unclear: $output"

rm "$live_file"
ln -s "$REPO_ROOT/home/agent-skills/agents/skills/$skill/SKILL.md" "$live_file"
mkdir -p "$home/.pi/agent/skills"
ln -s "$REPO_ROOT/home/agent-skills/agents/skills/$skill" "$home/.pi/agent/skills/$skill"
output="$(expect_failure 'redundant Pi skill' env HOME="$home" bash "$VERIFY" --live)"
[[ "$output" == *'redundant live skill'* ]] ||
    fail "duplicate-skill failure was unclear: $output"

rm "$home/.pi/agent/skills/$skill"
mkdir -p "$home/.agents/skills/playwright-cli" "$home/.pi/agent/skills/playwright-cli"
output="$(expect_failure 'third-party shared skill duplicated in Pi' env HOME="$home" bash "$VERIFY" --live)"
[[ "$output" == *'redundant shared skill in agent-specific directory'* ]] ||
    fail "third-party duplicate failure was unclear: $output"

echo 'agent skills live tests passed'
