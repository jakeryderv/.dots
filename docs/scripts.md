# scripts

Personal scripts. Deployed to `~/.local/bin/` (must be on your `PATH`).

See the root [README](../README.md) for shared deployment mechanics.

## Activate

```bash
cd ~/.dots && dots apply scripts
```

The row is `tree` mode, which matters here. A single symlink at `~/.local/bin`
would mean anything else installing there — such as
[`tools/install-npm-globals.sh`](../tools/README.md) — writes a third-party
file straight into the repo. As a `tree` row the target stays a real directory
holding one symlink per tracked file, beside everything else that lands there.

## Scripts

### `tmux-sessionizer`

fzf a project directory and attach or switch to a tmux session for it. Bound to
`prefix + f` in [`tmux`](tmux.md) and `Ctrl-F` in `shell/keybinds.sh`.

Vendored from ThePrimeagen/tmux-sessionizer at commit `7edf8211`, which is
unmaintained. It was previously fetched by an installer against a pinned commit
and checksum; keeping the file here removes that indirection and puts it under
the same ShellCheck and shfmt gates as the rest of `bin/`. The only local
changes are formatting and the fixes those gates required, each marked
`vendor fix` inline.

Search paths come from `~/.config/tmux-sessionizer/tmux-sessionizer.conf`, which
is **not tracked** — a fresh machine falls back to upstream's defaults
(`~/ ~/personal ...`), which are wrong for this setup.
