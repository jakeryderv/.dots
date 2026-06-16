# Global rules

## Environment
- Pop!_OS, bash. Python is the primary language.
- Always use `uv`, never pip.
- Editors: VS Code + Neovim — prefer CLI-driven workflows.

## Coding
- Modular design — small focused modules, clear boundaries, minimal coupling.
- Format and lint with ruff.
- Type hints when they add clarity, not ceremonially.

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
When tasked with a large feature or refactor, do not jump straight into coding. Follow this pipeline:
1. Delegate to `@explore` to find relevant files.
2. (Optional) Delegate to `@librarian` if external API references are needed.
3. Delegate to `@plan` to write a step-by-step technical spec. Wait for my approval.
4. Delegate to `@fixer` to implement the approved spec.
5. Delegate to `@review` to audit the code changes for correctness.
