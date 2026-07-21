# tmux

tmux config. Stowed to `~/.tmux.conf`.

See the root [README](../README.md) for shared stow mechanics.

## Files

| File | Role |
|------|------|
| `.tmux.conf` | Single-file config: prefix, display/colors, status bar, keybinds, plugins. |

## Activate

```bash
cd ~/.dots && stow tmux
```

Reload a running server with `prefix + R` (prefix is `Alt+a`).

## External dependencies

Not managed by stow — install separately:

- **TPM** (tmux plugin manager) — clone before plugins can install:

  ```bash
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ```

  Then reload and press `prefix + I` (capital i) to install the plugins listed
  at the bottom of `.tmux.conf` (resurrect, continuum, tmux-fzf).
- **fzf** and **tmux-sessionizer** — the session picker (`prefix + S`) and
  sessionizer (`prefix + f`) need these on `PATH`. Install via
  [`_helpers`](../_helpers/README.md) (`install-fzf.sh`,
  `install-tmux-sessionizer.sh`).

## Notable choices

- **Prefix `Alt+a`** — chosen so root `Ctrl+hjkl` stays free for
  vim-tmux-navigator, and to avoid the terminals' `ctrl+alt` tab/split keybinds.
- **Unified picker popups** — session switching (`prefix + S`), project sessions
  (`prefix + f`), and tmux-fzf (`prefix + F`) use 70% × 60% popups.
- **vim-tmux-navigator** — seamless `Ctrl+hjkl` pane/split navigation across
  tmux and Neovim (no plugin needed on the tmux side; the config detects vim).
- **Resize mode** — `prefix + r` enters a sticky mode where `hjkl`/`HJKL` resize
  panes until Escape/Enter/q.
- **Carbonfox-matched** status bar and pane borders.
- **Persistent mode badge** — the status bar shows `NORMAL`, `PREFIX`, `COPY`,
  or `RESIZE`, with a separate `SYNC` badge when pane synchronization is active.
- **True color + image passthrough** — `allow-passthrough` + terminal-features
  enable kitty/iTerm2 image protocols (used by [`nvim`](../nvim/README.md)'s
  `image.nvim`). Sixel is intentionally dropped (see the note in `.tmux.conf`).
- **continuum auto-restore is OFF** — sessions auto-save every 15 min but
  restore is manual (`prefix + Ctrl+r`).
