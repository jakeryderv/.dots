# TODO

Next up / ideas for the dotfiles repo.

- vscode
- hermes

## Agent workflow — deferred items (superpowers → OpenSpec migration, 2026-07-23)

Deliberately not implemented yet; each has a trigger. Don't batch-install
speculatively. Context: docs/claude.md history note.

**Next up (only uncovered gap):**

- pre-commit + linters (Ruff/Biome) + gitleaks — mechanical quality gates,
  per-repo. Replaces superpowers' hard gates; agent-agnostic. Natural pilot:
  agy-plugin-cc, possibly as a first end-to-end `/opsx:propose` change.

**Waiting on trigger:**

- `/wrap` command (tests → `/opsx:verify` → `/opsx:archive`) + PreToolUse hook
  blocking edits to `openspec/changes/archive/` — after the first real
  propose→apply→archive cycle shows what the workflow feels like.
- Stop hook (end-of-turn verification nag) — only if `/wrap` keeps getting
  forgotten. Cut by default: ceremony creep.
- TDD baked into OPSX schema templates (per-change-type) — only if
  implementation quality visibly slips without superpowers' TDD enforcement.
- Semgrep/Trivy in CI (report-only) — dev-toolbox week-2 tier.
- Serena / GitNexus / Repomix for code-intelligence grounding — if
  `/opsx:explore`/propose artifacts start mismatching actual code structure.
- Claude Squad / git worktrees per change folder — only when actually running
  parallel changes.

**Covered already (don't rebuild):** spec-compliance review = `/opsx:verify`;
code-quality review = `/agy:adversarial-review` / codex (cross-model); library
docs = Context7; change-state freshness = SessionStart hook in claude package.
