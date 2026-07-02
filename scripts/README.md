# scripts

Personal scripts. Stowed to `~/.local/bin/` (must be on your `PATH`).

See the root [README](../README.md) for shared stow mechanics.

## Activate

```bash
cd ~/.dots && stow scripts
```

## Scripts

### `dots`

Control-plane CLI for this repo's GNU Stow workflow. It resolves the repo from
its own symlink, defaults to `~/.dots` → `$HOME`, and dry-runs mutating stow
commands unless `--apply` is passed.

Useful commands:

```bash
dots status          # verify every package file resolves back to the repo
dots doctor          # repo health: git, ignores, READMEs, syntax, JSON, stow
dots stow            # dry-run all stow packages
dots stow --apply    # stow all packages
dots diff <pkg>      # compare live target files against repo sources
dots deps            # required/optional external command check
```

Run `dots help` for the full command list.

### `bs`

A composable `ls` replacement — a self-contained bash pipeline (gather → filter
→ sort → transform → format) with no dependencies beyond coreutils (`fzf`/`bat`
optional, used only by the interactive/preview modes).

Highlights:

- **Filters** — hidden/dirs/files/exec/links, glob/extension match, `--exclude`,
  min/max size, `--today`/`--week`.
- **Sorting** — time (default), size, name, extension; `--reverse`,
  `--group` (hidden first).
- **Output** — long, symlink targets, Nerd Font `--icons`, `--relative` times,
  `--tree` (with `-R`), `--json`, `--total`, `--summary`, `--no-color`.
- **Interactive** — `--fzf`, `--multi`, `--preview` (bat), `--edit` (open in
  `$EDITOR`).
- **Other** — `-R`/`--depth N`, `--git` status column, `--watch [N]`, and
  `--preset NAME` presets from `${XDG_CONFIG_HOME:-~/.config}/bs/config`.

Run `bs -h` for the full option list and a sample preset config.
