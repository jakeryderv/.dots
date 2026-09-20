# TODO

Next up / ideas for the dotfiles repo.

- vscode
- hermes

## Agent workflow — deferred items

Deliberately not implemented yet; each has a trigger. Don't batch-install
speculatively. Context: docs/claude.md history note.

**Next up (only uncovered gap):**

- pre-commit + linters (Ruff/Biome) + gitleaks — mechanical quality gates,
  per-repo. Replaces superpowers' hard gates; agent-agnostic. Natural pilot:
  agy-plugin-cc.

**Waiting on trigger:**

- Semgrep/Trivy in CI (report-only) — dev-toolbox week-2 tier.
- Claude Squad / git worktrees — only when actually running parallel changes.

**Covered already (don't rebuild):** code-quality review =
`/agy:adversarial-review` / codex (cross-model); library docs = Context7.
