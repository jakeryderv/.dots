#!/usr/bin/env bash
# SessionStart hook: surface active OpenSpec changes at the top of a session.
#
# Silent unless the session is in a real OpenSpec workspace AND that workspace
# has at least one active change. The standing "specs are the source of truth"
# rule lives in CLAUDE.md, so a banner here only earns its place when something
# is actually in flight.
#
# Workspace detection is delegated to the CLI, not to a `[ -d openspec ]` test:
#   - `openspec list` exits 0 everywhere, so exit status is not a usable guard.
#   - a bare directory test false-positives in ~/.dots, whose stow package is
#     literally named `openspec`, and false-negatives when a session starts in a
#     subdirectory of a real workspace.
# `root.source` is "nearest" only when the CLI resolved an actual workspace by
# walking up from the cwd, and "implicit" when it fell back to the cwd.

command -v openspec >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

json=$(openspec list --json 2>/dev/null) || exit 0
[ -n "$json" ] || exit 0

[ "$(jq -r '.root.source // empty' <<<"$json")" = "nearest" ] || exit 0
[ "$(jq '.changes | length' <<<"$json")" -gt 0 ] 2>/dev/null || exit 0

echo '=== Active OpenSpec changes ==='
openspec list
echo 'openspec/specs/ is the source of truth. Archived changes are history, not instructions.'
