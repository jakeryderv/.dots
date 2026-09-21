# scripts

Personal scripts. Deployed to `~/.local/bin/` (must be on your `PATH`).

See the root [README](../README.md) for shared deployment mechanics.

## Activate

```bash
cd ~/.dots && dots apply scripts
```

The row is `tree` mode, which matters here. A single symlink at `~/.local/bin`
would mean anything else installing there — such as
[the upstream uv installer](software.md) — writes a third-party
file straight into the repo. As a `tree` row the target stays a real directory
holding one symlink per tracked file, beside everything else that lands there.

## Scripts

### `herdr-move-mode`

A sticky "move mode" for [herdr](herdr.md) panes, bound to `prefix + m`: `hjkl`
or the arrows swap the focused pane with its neighbour in that direction, and
`Esc`/`Enter`/`q` exits. herdr has no user-defined key tables, so the key opens a
small popup that holds the keyboard while the script calls the socket API's
`pane.swap`. Focus stays on the moved pane; at a layout edge it reports that
there is no neighbour instead of wrapping. Needs `jq` and `socat`.

### `herdr-move-workspace`

Move the focused [herdr](herdr.md) workspace one place `up` or `down` in the
sidebar. Bound to `prefix + Shift+k/j`. herdr 0.8.2 has no keybinding action or
CLI subcommand for reordering workspaces, but its socket API has
`workspace.move` (what sidebar dragging uses), so the script sends that request
directly to `$HERDR_SOCKET_PATH`. It does nothing at either end of the list.
Needs `jq` and `socat`, both currently supplied by the host system.

### `tmux-sessionizer`

fzf a project directory and attach or switch to a tmux session for it. Bound to
`prefix + f` in [`tmux`](tmux.md) and `Ctrl-F` in `config/bash/bashrc`.

Vendored from ThePrimeagen/tmux-sessionizer at commit `7edf8211`, which is
unmaintained. It was previously fetched by an installer against a pinned commit
and checksum; keeping the file here removes that indirection and puts it under
the same ShellCheck and shfmt gates as the rest of `config/scripts/`. The only local
changes are formatting and the fixes those gates required, each marked
`vendor fix` inline.

Search paths come from `~/.config/tmux-sessionizer/tmux-sessionizer.conf`, which
is **not tracked** — a fresh machine falls back to upstream's defaults
(`~/ ~/personal ...`), which are wrong for this setup.
