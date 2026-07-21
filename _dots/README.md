# _dots

Repo-local tooling for managing this dotfiles repository.

**Not a stow package.** This directory is intentionally underscore-prefixed, so
the `dots` CLI excludes it from package discovery.

## Entrypoint

- `_dots/bin/dots` — control-plane CLI for Stow/package visibility, health
  checks, diffs, dependency checks, and bootstrap guidance.

Install the PATH entrypoint with the root setup script:

```bash
cd ~/.dots
./setup.sh
```

That creates:

```text
~/.local/bin/dots -> ~/.dots/_dots/bin/dots
```

## Common commands

```bash
dots status          # verify every package file resolves back to this repo
dots doctor          # repo health: git, ignores, READMEs, syntax, JSON, stow
dots stow            # dry-run all stow packages
dots stow --apply    # stow all packages
dots stow --no-folding --apply vim  # keep ~/.vim real; link tracked files inside
dots diff <pkg>      # compare live target files against repo sources
dots check           # portable syntax/parser/lint/behavior checks (CI-safe)
dots deps            # required/optional external command check
```

Run `dots help` for the full command list.

## Future growth

If the CLI grows, keep implementation details here instead of in `scripts/`:

- `lib/` for shared shell helpers
- `checks/` for doctor/status modules
- `tests/` for focused behavior checks
