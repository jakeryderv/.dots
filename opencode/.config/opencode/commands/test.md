---
description: Detect and run the project test suite, then analyze failures
---
Detect this project's normal test command from its files and conventions, then run the narrowest appropriate test suite. Prefer existing scripts over inventing commands.

Common choices include:
- Python: `uv run pytest`, `pytest`, or the project's configured test script
- Node/Bun: `npm test`, `pnpm test`, `yarn test`, or `bun test`
- Rust: `cargo test`
- Go: `go test ./...`
- Java: `mvn test` or `./gradlew test`
- .NET: `dotnet test`

If the test command is ambiguous, inspect config files first and ask only if it is still unclear. Run the chosen command. If anything fails, explain the root cause and propose a fix.
