# Global rules

## Environment
- Pop!_OS, bash.
- Editors: VS Code + Neovim — prefer CLI-driven workflows.
- Detect project tooling from repository files before running commands.

## Coding
- Modular design — small focused modules, clear boundaries, minimal coupling.
- Use the project's existing formatter, linter, package manager, and test runner.
- If tooling is unclear, inspect config files first; ask before introducing new tooling.
- Type hints when they add clarity, not ceremonially.

## Tool selection
- Use Glob/Grep/Read for local codebase discovery.
- Use Context7 for current library/framework documentation when the package is known.
- Use webfetch for known URLs and exact pages.
- Use websearch, when available, for discovery or current information without a known source.
- Use Playwright for browser behavior, UI state, screenshots, and frontend verification.
- Use sequential thinking only for complex planning, debugging, or tradeoff-heavy reasoning.
- Use language/project skills only when the project matches their scope.

## Communication
- Match depth to complexity — concise for simple things, detailed when it matters.
- Prefer tables, diagrams, and code examples over long prose.
- For big or architectural changes, propose a plan and wait for approval before implementing.

## Capability awareness
- Your available tools (built-in + MCP servers) are provided to you each session —
  use them as needed.
- To see what's *configured* (providers, MCP servers, agents, commands), read
  ~/.config/opencode/opencode.json and the agents/ + commands/ dirs (tracked in ~/.dots).
- When a task would clearly benefit from a capability you don't have, propose the
  specific addition (name the server/plugin/tool + exact config) instead of forcing
  a workaround. Suggest, don't self-install.

## Complex Task Workflow (Ultrawork)
For architectural, high-risk, or broad cross-cutting work, use this pipeline:
1. Delegate to `@explore` to find relevant files.
2. (Optional) Delegate to `@librarian` if external API references are needed.
3. Delegate to `@plan` to write a step-by-step technical spec. Wait for my approval.
4. Delegate to `@fixer` to implement the approved spec.
5. Delegate to `@review` to audit the code changes for correctness.

For focused or moderate changes, inspect the relevant files, implement directly,
and run targeted verification without forcing the full delegation pipeline.
