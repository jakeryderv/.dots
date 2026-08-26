# herdr

[Herdr](https://herdr.dev) — a terminal workspace manager for AI coding agents
(panes, tabs, workspaces, git worktrees, and agent lifecycle detection).
Installed to `~/.local/bin/herdr` by its own installer; config deployed to
`~/.config/herdr/`.

See the root [README](../README.md) for shared deployment mechanics.

## Files

| File | Role |
|------|------|
| `config.toml` | The only user-authored file. Everything else in `~/.config/herdr/` is runtime state. |

Only keys that differ from upstream are set, so future default changes are
inherited rather than pinned. Print the full annotated default — every key with
its default value commented out — with `herdr --default-config`.

## Activate

```bash
just apply herdr
herdr server reload-config   # a running server re-reads config.toml
```

Validate before reloading with `herdr config check`. It is a real check, not a
TOML parse: it rejects unknown keys, unparseable keybindings, and out-of-range
enum values, naming the expected variants.

```
$ herdr config check
config: issues found
unknown config key keys.bogus_option_xyz; ignoring key
invalid keybinding: keys.split_vertical = "prefix+notarealkey"; disabling binding
```

## Why `tree` mode

Herdr keeps its runtime state in the same directory it reads config from:

| Path | Written by |
|------|-----------|
| `herdr.sock`, `herdr-client.sock` | the server, on every start |
| `herdr-server.log`, `herdr-client.log` | append-only logs |
| `session.json` | workspace/pane layout, saved every few seconds |
| `.plugins.lock` | plugin machinery |

A `link` row would place one symlink at `~/.config/herdr`, which would land all
of that inside this repo. `tree` gives a real directory holding one symlink per
tracked file, so state stays in `$HOME`. The `.gitignore` entries for these
paths are a backstop for state copied in by hand, not the primary defence.

Agent-detection manifests, which Herdr refreshes from herdr.dev when
`update.manifest_check` is true, live outside the config dir in
`~/.local/state/herdr/agent-detection/` and are cache — not tracked.

## Running alongside tmux

Herdr and [`tmux`](tmux.md) are siblings, each in its own Ghostty tab, never
nested. tmux keeps the sessions and the layout; herdr drives agent work.

```
Ghostty ─┬─ tab 1 ─ tmux  (prefix Alt+a)
         └─ tab 2 ─ herdr (prefix Ctrl+b)
```

`Ctrl+tab` switches between them; each tab names itself, so they are tellable
apart at a glance. Two tabs is the entire Ghostty layout — splits and panes
belong to the layer inside each tab, which is why
[`ghostty`](ghostty.md) gave up its split bindings and the `ctrl+alt` and
`alt+digit` namespaces.

Nesting was tried and reverted. It works — upstream supports tmux as a host
("runs inside your existing terminal ... even inside tmux") — but it costs a
doubled status bar, a doubled render, and tmux copy mode capturing herdr's
rendered frame instead of the pane's scrollback. Separate tabs keep each
layer's mouse, scrollback, and prefix intact. The arrangement upstream actually
warns against is the reverse: a tmux session *inside* a herdr pane disables
agent state detection, so agents run directly in herdr panes.

`Ctrl+b` is free because `.tmux.conf` unbinds it (`unbind C-b`, prefix moved to
`Alt+a`). The two prefixes never collide, which is the problem most people
combining these tools have to solve first and this setup never had.

## Keys

| Namespace | Owner |
|-----------|-------|
| `Alt+a` | tmux prefix |
| `Ctrl+h/j/k/l`, `Ctrl+\` | vim-tmux-navigator, in the tmux tab |
| `Ctrl+b` | **herdr** |
| `ctrl+alt+*`, `alt+1..9` | released by Ghostty for herdr's use |
| `Ctrl+Shift+*` | Ghostty — tabs, clipboard, command palette |

Herdr's defaults are already tmux-shaped, so most of the keymap is inherited.
What `config.toml` changes or adds:

| Key | Action | Why |
|-----|--------|-----|
| `prefix + \` | Split side by side | Matches tmux's `\|` |
| `prefix + -` | Split stacked | Default; already matches |
| `prefix + ↑` / `↓` | Previous / next workspace | Unbound upstream; sidebar stacks vertically |
| `prefix + Shift+1..9` | Switch workspace | Unbound upstream |
| `prefix + a` / `Shift+a` | Next / previous agent | Unbound upstream, and the point of the tool |
| `prefix + Alt+1..9` | Focus agent by index | Upstream's own example — unreachable until Ghostty released `alt+1..9` |
| `Ctrl+Shift+Alt+←↓↑→` | Resize pane directly | The chords Ghostty used for `resize_split` |
| `prefix + Shift+←` / `→` | Move tab | — |
| `` prefix + ` `` | Floating terminal popup | Mirrors tmux's `Alt+`` ` `` toggle-popup, same 80%×80% |
| `prefix + Alt+g` | lazygit popup | Same dimensions |

`Ctrl+h/j/k/l` is left unbound here on purpose: herdr forwards it to the focused
pane, so nvim inside a herdr pane keeps its own window navigation. Pane
movement is on the prefix instead.

**Split naming is inverted from tmux.** Herdr names a split after the divider's
orientation; tmux names it after the flag:

| Herdr | Divider | Result | tmux equivalent |
|-------|---------|--------|-----------------|
| `split_vertical` | vertical | side by side | `split-window -h` |
| `split_horizontal` | horizontal | stacked | `split-window -v` |

Ignore the word and match the glyph — `\` is side by side and `-` is stacked in
all three of herdr, Ghostty, and tmux. The CLI is unambiguous where the config
is not: `herdr pane split --direction right|down`.

## Theme

`theme.name = "terminal"` inherits the host terminal palette rather than using a
built-in, so carbonfox is defined once in
[`ghostty`](ghostty.md)'s `carbonfox.ghostty` and herdr borrows it — including
over SSH, where the remote server picks up whatever the local terminal uses.

`panel_bg = "reset"` emits no background color for panes rather than painting
one, which lets Ghostty's `background-image` wallpaper show through. Set it to a
hex value to paint solid panels instead.

## Mouse and clipboard

`mouse_capture` is left at its default (`true`), which means herdr consumes
clicks before the terminal sees them — the same situation `mouse on` creates in
tmux. Neither Ghostty's `ctrl+click` URL opening nor the `C-MouseDown1Pane`
hyperlink binding described in [`tmux`](tmux.md) reaches a herdr pane.

Two escape hatches, neither currently enabled:

- `ui.mouse_capture = false` hands all clicks back to the terminal.
- `ui.right_click_passthrough_modifier` forwards only right-click hold/drag to
  pane apps. Shift is deliberately unsupported upstream, because terminals
  commonly reserve Shift+mouse — which is exactly what Ghostty's
  `mouse-shift-capture = false` relies on.

## Notifications

`ui.toast.delivery = "system"` asks the OS notification service directly when a
background agent finishes or blocks.

This is a deliberate exception to the policy in `config.ghostty`, which disables
every bell (`bell-features = no-system,no-audio,no-attention,no-title,no-border`)
and trims desktop notifications to config-reload only. A bell is the terminal
being noisy; this is an agent asking for input. Set `delivery = "herdr"` for an
in-app toast instead, or `"off"` to leave state in the sidebar only.
`[ui.sound]` is left enabled at its default.

## Caveat: `herdr config reset-keys`

That command backs up `config.toml` and writes a fresh one. If it replaces the
file rather than editing it in place, it will clobber the symlink and leave a
real file at `~/.config/herdr/config.toml` — `just status herdr` then reports a
conflict. Adopt any wanted changes back into `config/herdr/config.toml` and
re-run `just apply herdr`.

## Updates

Herdr self-updates (`herdr update`, channel via `herdr channel set
<stable|preview>`), so the binary is not managed here — only the config is.
