---
name: uv-python
description: Use when working in a Python project — uv commands, project setup, and the test/lint loop. Always use uv, never pip.
---

# uv + Python workflow

Always use `uv`. Never use `pip`, `python -m venv`, or `poetry`.

## Dependencies
- Add a dependency: `uv add <pkg>`
- Add a dev dependency: `uv add --dev <pkg>` (pytest, ruff, etc.)
- Remove: `uv remove <pkg>`
- Sync the environment from the lockfile: `uv sync`
- Update the lockfile: `uv lock`

## Running things
- `uv run python ...`
- `uv run pytest` — run the test suite
- `uv run ruff check .` — lint
- `uv run ruff format .` — format
- Prefer `uv run <cmd>` over activating a venv manually.

## New package
- Scaffold: `uv init --package <name>` (gives a `src/` layout + `pyproject.toml`)
- Keep modules small and focused with clear boundaries.
- Configure pytest and ruff in `pyproject.toml`.

## Testing (TDD)
1. Write pytest tests first that capture the desired behavior.
2. Confirm they fail.
3. Implement the minimal code to make them pass.

Related commands: `/test` (pytest), `/lint` (ruff), `/cov` (coverage).
