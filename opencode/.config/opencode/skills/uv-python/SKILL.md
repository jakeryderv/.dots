---
name: uv-python
description: Use when working in a Python project — uv commands, project setup, and the test/lint loop. Always use uv, never pip.
---

# uv + Python workflow

Use this skill only for Python projects. Prefer `uv` for Python environment, dependency, and command execution workflows. Do not use `pip`, `python -m venv`, or `poetry` unless the project explicitly requires them.

## Detection
- Python project markers: `pyproject.toml`, `uv.lock`, `requirements*.txt`, `setup.py`, `setup.cfg`, `tox.ini`, `noxfile.py`, `pytest.ini`, or Python package/module files.
- If `uv.lock` or `[tool.uv]` exists, treat `uv` as authoritative.
- If the repo uses another Python tool intentionally, follow the repo unless asked to migrate.

## Dependencies
- Add a dependency: `uv add <pkg>`
- Add a dev dependency: `uv add --dev <pkg>` (pytest, ruff, etc.)
- Remove: `uv remove <pkg>`
- Sync the environment from the lockfile: `uv sync`
- Update the lockfile: `uv lock`
- Upgrade a package intentionally: `uv add <pkg>@latest` or edit constraints then `uv lock`
- Export requirements only when needed by deployment tooling: `uv export ...`

## Running things
- `uv run python ...`
- `uv run pytest` — run the test suite
- `uv run ruff check .` — lint
- `uv run ruff format .` — format
- `uv run mypy` or `uv run pyright` — type check when configured
- Prefer `uv run <cmd>` over activating a venv manually.

## Tests, lint, and coverage
- Prefer project-defined commands in `pyproject.toml`, task runners, Makefiles, or docs.
- Default test command: `uv run pytest`.
- Focused test command: `uv run pytest path/to/test_file.py::test_name`.
- Default lint command: `uv run ruff check .`.
- Default format command: `uv run ruff format .`.
- Coverage when configured: `uv run pytest --cov --cov-report=term-missing`.
- Do not add coverage, typing, or lint dependencies without asking unless the task explicitly requires setup.

## New package
- Scaffold: `uv init --package <name>` (gives a `src/` layout + `pyproject.toml`)
- Keep modules small and focused with clear boundaries.
- Configure pytest and ruff in `pyproject.toml`.

## Existing projects
- Preserve the current layout (`src/`, flat package, app package, etc.).
- Keep dependency constraints compatible with the project's supported Python versions.
- Check `requires-python` before using newer syntax or stdlib features.
- Avoid broad migrations unless explicitly requested.

## Testing (TDD)
1. Write pytest tests first that capture the desired behavior.
2. Confirm they fail.
3. Implement the minimal code to make them pass.

Related generic commands: `/test`, `/lint`, `/cov`. They should detect this Python workflow when used inside a Python project.
