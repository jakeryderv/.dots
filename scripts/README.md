# scripts

Personal scripts. Stowed to `~/.local/bin/` (must be on your `PATH`).

See the root [README](../README.md) for shared stow mechanics.

## Completions

Each script ships a bash completion in
`.local/share/bash-completion/completions/`, named after the command. They are
autoloaded on first Tab rather than at shell startup, so they cost nothing until
used and disappear along with the script if this package is unstowed. They need
the `bash-completion` package, which `_bash/completions.sh` already sources; if
it is missing, Tab silently falls back to filename completion.

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

### `gconf`

Inspects and edits git config by scope, rendering `section.key = value` with the
scope (and optionally the source file) in an aligned left column.

```bash
gconf              # every scope, merged and labeled
gconf g            # global list
gconf g e          # edit ~/.gitconfig
gconf g o          # global list, annotated with the file each value came from
gconf local edit   # long forms work too
NO_COLOR=1 gconf   # standard no-color convention
```

Scopes are `l|local`, `g|global`, `s|system`, `a|all` (default); actions are
`l|list` (default), `e|edit`, `o|origin`. `all` has no single file, so it
rejects `edit`. `--color=always|never|auto` overrides the tty check.

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
