# scripts

Personal scripts. Stowed to `~/.local/bin/` (must be on your `PATH`).

See the root [README](../README.md) for shared stow mechanics.

## Activate

```bash
cd ~/.dots && stow scripts
```

## Scripts

### `tmux-cheatsheet`

Generates a reference from a running tmux server's effective prefix, root, vi
copy-mode, and custom resize-mode key tables. It includes defaults, overrides,
and loaded plugin bindings. The tmux config opens its order-preserving fzf mode
with `prefix + ?`.

```bash
tmux-cheatsheet             # colored terminal output
tmux-cheatsheet --pick      # interactive fzf picker
tmux-cheatsheet --plain     # plain output for logs and pipes
NO_COLOR=1 tmux-cheatsheet  # standard no-color convention
```

`tmux` and a running server are required for every mode; `--pick` also requires
`fzf`.

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
