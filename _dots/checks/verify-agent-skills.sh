#!/usr/bin/env bash
# Validate the tracked shared-skill tree. Pass --live after deploying to also
# verify the four agents resolve canonical copies without local duplicates.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CANONICAL_ROOT="$REPO_ROOT/home/agent-skills/agents/skills"
CLAUDE_ROOT="$REPO_ROOT/home/agent-skills/claude/skills"
MANIFEST="$REPO_ROOT/docs/agent-skills.md"
CHECK_LIVE=0

if [[ "${1:-}" == "--live" ]]; then
    CHECK_LIVE=1
elif (($#)); then
    printf 'usage: %s [--live]\n' "$0" >&2
    exit 2
fi

fail() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

same_path() {
    local left right
    left="$(readlink -f "$1" 2>/dev/null || true)"
    right="$(readlink -f "$2" 2>/dev/null || true)"
    [[ -n "$left" && "$left" == "$right" ]]
}

verify_live_tree_skill() {
    local skill_dir="$1" skill_name="$2"
    local source_rel="${skill_dir#"$REPO_ROOT"/}"
    local live_dir="$HOME/.agents/skills/$skill_name"
    local tracked rel live_file

    [[ -d "$live_dir" && ! -L "$live_dir" ]] ||
        fail "$live_dir must be a real tree-deployment directory"

    while IFS= read -r tracked; do
        rel="${tracked#"$source_rel"/}"
        live_file="$live_dir/$rel"
        [[ -e "$live_file" || -L "$live_file" ]] || fail "missing live skill file: $live_file"
        same_path "$live_file" "$REPO_ROOT/$tracked" ||
            fail "$live_file does not resolve to the canonical source"
    done < <(git -C "$REPO_ROOT" ls-files -- "$source_rel")
}

[[ -d "$CANONICAL_ROOT" ]] || fail "missing canonical skill root: $CANONICAL_ROOT"
[[ -d "$CLAUDE_ROOT" ]] || fail "missing Claude compatibility root: $CLAUDE_ROOT"

mapfile -t skill_dirs < <(find "$CANONICAL_ROOT" -mindepth 1 -maxdepth 1 -type d -print | sort)
((${#skill_dirs[@]})) || fail 'canonical skill root is empty'

declare -A seen_names=()
for skill_dir in "${skill_dirs[@]}"; do
    folder_name="${skill_dir##*/}"
    skill_file="$skill_dir/SKILL.md"
    [[ -f "$skill_file" ]] || fail "$folder_name is missing SKILL.md"
    [[ "$(sed -n '1p' "$skill_file")" == '---' ]] || fail "$folder_name/SKILL.md has no YAML frontmatter"

    skill_name="$(sed -nE '2,/^---$/s/^name:[[:space:]]*([a-z0-9-]+)[[:space:]]*$/\1/p' "$skill_file" | head -n 1)"
    [[ -n "$skill_name" ]] || fail "$folder_name/SKILL.md has no name field"
    [[ "$skill_name" == "$folder_name" ]] || fail "skill name $skill_name does not match folder $folder_name"
    [[ -z "${seen_names[$skill_name]:-}" ]] || fail "duplicate skill name: $skill_name"
    seen_names[$skill_name]=1

    grep -Fq "| \`$skill_name\` |" "$MANIFEST" || fail "$skill_name is missing from the README manifest"

    claude_link="$CLAUDE_ROOT/$skill_name"
    [[ -L "$claude_link" ]] || fail "missing Claude mirror link for $skill_name"
    [[ "$(readlink "$claude_link")" == "../../agents/skills/$skill_name" ]] || fail "incorrect Claude mirror target for $skill_name"
    [[ "$(readlink -f "$claude_link")" == "$(readlink -f "$skill_dir")" ]] || fail "broken Claude mirror link for $skill_name"

    [[ ! -e "$REPO_ROOT/home/pi/agent/skills/$skill_name" && ! -L "$REPO_ROOT/home/pi/agent/skills/$skill_name" ]] ||
        fail "Pi still has a redundant local copy of $skill_name"
    [[ ! -e "$REPO_ROOT/config/opencode/skills/$skill_name" && ! -L "$REPO_ROOT/config/opencode/skills/$skill_name" ]] ||
        fail "OpenCode still has a redundant local copy of $skill_name"

    if ((CHECK_LIVE)); then
        verify_live_tree_skill "$skill_dir" "$skill_name"

        live_path="$HOME/.claude/skills/$skill_name"
        [[ -e "$live_path" ]] || fail "missing live skill: $live_path"
        same_path "$live_path" "$skill_dir" || fail "$live_path does not resolve to the canonical skill"

        for duplicate_path in \
            "$HOME/.codex/skills/$skill_name" \
            "$HOME/.pi/agent/skills/$skill_name" \
            "$HOME/.config/opencode/skills/$skill_name"; do
            [[ ! -e "$duplicate_path" && ! -L "$duplicate_path" ]] || fail "redundant live skill: $duplicate_path"
        done
    fi
done

while IFS= read -r entry; do
    [[ -n "${seen_names[$entry]:-}" ]] || fail "orphaned Claude skill link: $entry"
done < <(find "$CLAUDE_ROOT" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort)

if ((CHECK_LIVE)); then
    agent_root="$HOME/.pi/agent/skills"
    if [[ -d "$agent_root" ]]; then
        while IFS= read -r entry; do
            [[ -e "$HOME/.agents/skills/$entry" || -L "$HOME/.agents/skills/$entry" ]] || continue
            fail "redundant shared skill in agent-specific directory: $agent_root/$entry"
        done < <(find "$agent_root" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -printf '%f\n' | sort)
    fi
fi

printf 'Shared agent skills valid (%d canonical skills).\n' "${#skill_dirs[@]}"
