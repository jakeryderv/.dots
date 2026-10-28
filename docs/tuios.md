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
(`prefix ,`), `tuios set-config`, the keybind manager and `tuios plugins` all
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

## Running alongside tmux and herdr

Its own Ghostty window, never nested, like tmux and herdr. herdr refuses to
start inside a tuios pane, and tuios drops `TMUX`/`HERDR_*` variables it
inherits.

tuios does impersonate herdr *inside its own panes*. Every pane gets
`HERDR_ENV=1`, `HERDR_PANE_ID`, `HERDR_SOCKET_PATH` (tuios's herdr-compatible
socket) and `HERDR_BIN_PATH` (a `herdr` link to tuios). Consequences:

- Neovim's navigation config takes its herdr branch in tuios, and asks tuios's
  herdr shim for `vim-herdr-navigation`. Until that plugin is installed and
  enabled in tuios (`tuios plugins install`, `tuios plugins enable`), nvim
  warns that the bridge is unavailable and Ctrl+hjkl stays inside nvim.
- The herdr Claude hook (`config/claude/settings.json`) runs in tuios panes and
  reports to tuios's socket.

## Updates

`tuios update` replaces the binary (`tuios update --check` only reports). Then
refresh completions with `dots install completions`.
