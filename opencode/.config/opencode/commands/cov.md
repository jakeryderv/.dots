---
description: Detect and run project coverage, then highlight gaps
---
Detect this project's normal coverage command from its files and conventions, then run it. Prefer existing scripts or documented project commands over inventing new tooling.

Common choices include:
- Python: `uv run pytest --cov --cov-report=term-missing`, `coverage run -m pytest`, or configured scripts
- Node/Bun: `npm run coverage`, `pnpm coverage`, `yarn coverage`, `bun test --coverage`, `vitest --coverage`, or `jest --coverage`
- Rust: configured `cargo llvm-cov` or `cargo tarpaulin`
- Go: `go test -cover ./...`
- Java/.NET: project-specific coverage tasks

If coverage tooling is not configured, say so and suggest the smallest project-appropriate addition instead of installing anything. Review the report, identify the least-covered modules, and suggest tests for the highest-risk gaps.
