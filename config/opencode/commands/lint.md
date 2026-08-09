---
description: Detect and run the project linter, then summarize issues
---
Detect this project's normal lint/static-check command from its files and conventions, then run it. Prefer existing package scripts or documented project commands over inventing new tooling.

Common choices include:
- Python: `uv run ruff check .`, `ruff check .`, `uv run mypy`, or configured scripts
- Node/Bun: `npm run lint`, `pnpm lint`, `yarn lint`, `bun run lint`, `eslint`, or framework checks
- Rust: `cargo clippy`
- Go: `go vet ./...` or configured golangci-lint
- Java: Maven/Gradle check tasks
- .NET: `dotnet format --verify-no-changes` or analyzer tasks

If the lint command is ambiguous, inspect config files first and ask only if it is still unclear. Summarize issues by category and suggest fixes for anything that is not auto-fixable.
