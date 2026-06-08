# Global rules

## Environment
- Pop!_OS, bash. Python is the primary language.
- Always use `uv`, never pip.
- Editors: VS Code + Neovim — prefer CLI-driven workflows.

## Coding
- Modular design — small focused modules, clear boundaries, minimal coupling.
- Prefer TDD: write pytest tests first, then implement to pass them.
- Format and lint with ruff.
- Type hints when they add clarity, not ceremonially.

## Communication
- Match depth to complexity — concise for simple things, detailed when it matters.
- Prefer tables, diagrams, and code examples over long prose.
- For big or architectural changes, propose a plan and wait for approval before implementing.
