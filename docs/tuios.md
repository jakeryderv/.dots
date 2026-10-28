# tuios

[tuios](https://tuios.dev) — a terminal window manager with agent awareness:
tiling panes, workspaces, a daemon that keeps sessions across restarts, and an
Inbox for coding agents. On trial beside [`tmux`](tmux.md) and
[`herdr`](herdr.md). Installed to `~/.local/bin/tuios` by its upstream
installer (see the [software inventory](software.md#editor-and-shell-tools));
config deployed to `~/.config/tuios/`.

See the root [README](../README.md) for shared deployment mechanics.

## Files

| File | Role |
|------|------|
| `config.d/dots.toml` | The repo's baseline. The only tracked file. |

## Activate

```bash
dots apply tuios
tuios config origin          # every key, and the file that sets it
```

tuios watches every config file, through symlinks to their targets, so a save
takes effect at once. A file with an error is not applied: tuios keeps the
settings in use and shows the error on screen. There is no `config check`
command; `tuios config files` and `tuios config origin` are the after-edit
check.

## Layering: why `config.d` and not `config.toml`

tuios reads the files in its `include` list, then `config.d/*.toml` in name
order, then `config.toml`; a later file wins. The settings page
(`prefix C`), `tuios set-config`, the keybind manager and `tuios plugins` all
write the config, changing only the lines of the key and keeping comments:

| Change | Lands in |
|--------|----------|
| A key some file already sets | the last file that sets it |
| A new key | `config.toml` |
| A removed key | removed from every file that sets it |

So the tracked file is a `config.d` drop-in, and `config.toml` stays tuios's.
Changing a repo-owned key in the app writes through the symlink into
`config/tuios/config.d/dots.toml`, where it shows up in `git diff`. A new key
tried in the app lands in the untracked `config.toml`; move it into `dots.toml`
to keep it. Every write resolves the symlink and renames a temp file over its
target, so the link survives.

`config.d/look.toml` is reserved: `tuios look apply` writes it, and it sorts
after `dots.toml`. Don't name a tracked file that.

On first start tuios writes `[startup] daemon = true, tiled = true` into
`config.toml` unless another file sets them. They live in `dots.toml` instead.
If `config.toml` predates the package, delete its `[startup]` table, or run
`tuios config reset` (it asks first), and check `tuios config origin startup`.

## Why `tree` mode

`~/.config/tuios/` holds more than config:

| Path | Written by |
|------|-----------|
| `config.toml` | tuios on first start, then the settings page and friends |
| `layouts/` | saving a layout template in the app |
| `themes/`, `glyphs/` | created empty; custom themes and glyph sets go here |
| `config.d/look.toml` | `tuios look apply` |
| `plugins/`, `plugin-config/` | plugins and their settings |
| `authorized_keys`, `web-password`, `ntfy-token`, `pushover-token` | the SSH and web servers, push alerts — secrets |

A `link` row would put all of that inside this repo. `tree` gives a real
directory holding one symlink per tracked file. The `.gitignore` entries for
these paths are a backstop. Sessions and the daemon log live in
`~/.local/state/tuios/`, worktrees and plugin checkouts in
`~/.local/share/tuios/`, the socket in `/run/user/<uid>/tuios/`.

## Keys

The [tmux preset](https://tuios.dev/docs/keybindings) with tmux's and herdr's
prefix, **`Alt+a`**, then the differences [`tmux.conf`](tmux.md) and
[herdr's config](herdr.md) already share. In the preset a tmux *window* is a
tuios **workspace** and a tmux *pane* is a tuios **window**, so `c`, `n`/`p`,
`,`, `1`-`9`, `|`, `-`, `;`, `z`, `d`, `x`, `[`, `s`, `$` and `?` after the
prefix do what they do in tmux. `tuios keybinds cheatsheet tmux` lists what
moved; tuios features the preset displaced are under `prefix Ctrl+t`.

| After `Alt+a` | Does | Instead of (preset or tuios default) |
|---|---|---|
| `h` / `l` | previous / next workspace (`p`/`n` kept) | `l` last workspace |
| `k` / `j` | previous / next session (`(`/`)` kept) | `k` keybind manager, `j` newest message |
| `H` / `L` | move the workspace left / right | `H` other rail, `L` last session |
| `r` | sticky resize menu: `hjkl`/arrows by 5, `HJKL` by 20 | `r` reload |
| `m` | sticky move menu: `hjkl`/arrows swap panes | `m` mark pane |
| `R` | reload config | `R` rotate split |
| `X` | close the workspace | `X` close session |
| `v` | copy mode (`[` kept) | `v` agent review |
| `*` | type into every pane on the workspace | |
| `N` | new session | `N` last message |
| `` ` `` | floating zsh, 80%x80% (herdr's `prefix+backtick`) | |
| `Alt+g` | lazygit popup, 80%x80% | |

`Esc` ends the resize and move menus. Any key a menu does not bind also ends
it, and goes to the pane: unlike tmux's key tables, `q` and `Enter` are typed,
not swallowed. Settings are on `C`, the palette on `:` and `P`, the launcher on
`a`.

**Without the prefix**, `Ctrl+h/j/k/l` run vim-herdr-navigation (below), as in
herdr. The keys tuios takes from every pane by default are unbound:
`Ctrl+p` (palette), `Alt+Space` (launcher), `Alt+arrows` (focus),
`Alt+n`/`Alt+p` (windows) and `Alt+1`-`9` (workspaces). Still taken, as
nothing here uses them: `Alt+Esc` (window mode), `Shift+arrows`/`Shift+PgUp`
(scrollback), `Ctrl+Shift+v` (paste), and `Alt+Shift`/`Ctrl+Alt` with a digit
(move a pane between workspaces).

**Not lock mode.** `keybindings.lock` gives a pane every key but the leader,
which would keep tuios's keys out of the panes in one line. But command keys
are ordinary actions, dispatched after lock's early return, so the
`Ctrl+h/j/k/l` command keys would be typed into the pane too. Hence the
targeted unbinds.

`tuios keybinds doctor` checks the result: conflicts, keys taken from the
pane, and preset keys these bindings displace. `tuios keybinds list` shows the
effective map.

## Running alongside tmux and herdr

Its own Ghostty window, never nested, like tmux and herdr. herdr refuses to
start inside a tuios pane, and tuios drops `TMUX`/`HERDR_*` variables it
inherits.

tuios does impersonate herdr *inside its own panes*. Every pane gets
`HERDR_ENV=1`, `HERDR_PANE_ID`, `HERDR_SOCKET_PATH` (tuios's herdr-compatible
socket) and `HERDR_BIN_PATH` (a `herdr` link to tuios). Consequences:

- Neovim's navigation config takes its herdr branch in tuios, and asks tuios's
  herdr shim for `vim-herdr-navigation`. tuios finds herdr's own checkout of
  the plugin (`tuios plugins list` shows it `from herdr`), so `dots.toml` only
  enables it: nothing is installed and there is no `plugins.lock`. The
  `Ctrl+h/j/k/l` command keys run its actions, as herdr's `config.toml` does.
  Remove it from `[plugins] enabled` and nvim warns that the bridge is
  unavailable, and Ctrl+hjkl stays inside nvim.
- The herdr Claude hook (`config/claude/settings.json`) runs in tuios panes and
  reports to tuios's socket.

## Updates

`tuios update` replaces the binary (`tuios update --check` only reports). Then
refresh completions with `dots install completions`.
