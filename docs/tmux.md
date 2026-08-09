# tmux

tmux config. Stowed to `~/.tmux.conf`.

See the root [README](../README.md) for shared stow mechanics.

## Files

| File | Role |
|------|------|
| `.tmux.conf` | Single-file config: prefix, display/colors, status bar, keybinds, plugins. |

The generated cheatsheet command is provided by
[`scripts`](../scripts/README.md) as `~/.local/bin/tmux-cheatsheet`.

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
  at the bottom of `.tmux.conf` (resurrect, continuum, tmux-fzf, and
  extrakto).
- **fzf** and **tmux-sessionizer** — the generated cheatsheet (`prefix + ?`),
  session picker (`prefix + S`), and sessionizer (`prefix + f`) need these on
  `PATH`. Install via
  [`_helpers`](../_helpers/README.md) (`install-fzf.sh`,
  `install-tmux-sessionizer.sh`).

## Links, mouse, and clipboard

These behaviors are split across this config and
[`ghostty`](../ghostty/README.md); neither half makes sense alone.

**Clickable links.** `terminal-features` declares `hyperlinks`, which is what
lets tmux store OSC 8 hyperlinks and forward them to the terminal. Three ways to
follow one:

| Gesture | Handled by |
|---------|------------|
| `o` in copy mode, cursor on the link | tmux → `xdg-open` |
| `Ctrl+click` | tmux → `xdg-open` |
| `Shift+Ctrl+click` | Ghostty, bypassing tmux entirely |

`mouse on` means tmux consumes mouse events before Ghostty sees them, so the
plain `Ctrl+click` that opens links outside tmux would otherwise do nothing —
hence the explicit binding. Shift is the escape hatch: Ghostty's
`mouse-shift-capture = false` makes Shift bypass mouse reporting, so the click
reaches the terminal. That is also how you select text with the mouse for
Ghostty's own clipboard rather than tmux's.

Both tmux bindings escape the URL with `#{q:...}`. A hyperlink is program output
and OSC 8 lets the visible text differ from the destination, so an unescaped URL
is a shell injection — see the comment in `.tmux.conf`.

**Clipboard.** `set-clipboard on` copies out over OSC 52, which Ghostty allows
by default (`clipboard-write = allow`) while prompting on reads
(`clipboard-read = ask`). Mouse drags stay highlighted on release, and `y` in
copy mode copies and exits. Both routes reach the system clipboard, so no
`xclip`/`wl-copy` dependency.

Producers matter too: [`git`](../git/README.md) sets `delta.hyperlinks = true`,
which is what makes file names and commit hashes in diffs clickable in the first
place.

## Notable choices

- **Prefix `Alt+a`** — chosen so root `Ctrl+hjkl` stays free for
  vim-tmux-navigator, and to avoid the terminals' `ctrl+alt` tab/split keybinds.
- **Generated keybinding cheatsheet** — `prefix + ?` opens a searchable popup
  built from tmux's live effective bindings, including defaults, overrides,
  custom modes, and plugin bindings. Type to filter, `Ctrl+U` to clear the
  query, and `Escape` or `Ctrl+C` to close. The backing command also supports
  `--plain`/`--no-color` output for logs, pipes, and tests.
- **Unified picker popups** — session switching (`prefix + S`), project sessions
  (`prefix + f`), and tmux-fzf (`prefix + F`) use 70% × 60% popups.
- **Terminal text extraction** — Extrakto (`prefix + Tab`) fuzzy-finds text,
  paths, URLs, and lines from pane history; `Tab` inserts and `Enter` copies.
- **Full-window native chooser** — `prefix + s` temporarily zooms the active
  pane so tmux's built-in session tree and preview use the entire window.
- **vim-tmux-navigator** — seamless `Ctrl+hjkl` pane/split navigation across
  tmux and Neovim (no plugin needed on the tmux side; the config detects vim).
- **Resize mode** — `prefix + r` enters a sticky mode where `hjkl`/`HJKL` resize
  panes until Escape/Enter/q.
- **Carbonfox-matched** status bar and pane borders.
- **Persistent state badges** — the status bar shows `NORMAL`, `PREFIX`, `COPY`,
  or `RESIZE`, with separate `SYNC` and `ZOOM` badges when pane synchronization
  or pane zoom is active.
- **True color + image passthrough** — `allow-passthrough` + terminal-features
  enable kitty/iTerm2 image protocols (used by [`nvim`](../nvim/README.md)'s
  `image.nvim`). Sixel is intentionally dropped (see the note in `.tmux.conf`).
- **continuum auto-restore is OFF** — sessions auto-save every 15 min but
  restore is manual (`prefix + Ctrl+r`).
