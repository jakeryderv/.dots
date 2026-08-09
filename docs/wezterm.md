# wezterm

[WezTerm](https://wezterm.org) terminal config. Deployed to `~/.config/wezterm/`.

See the root [README](../README.md) for shared deployment mechanics.

## Files

| File | Role |
|------|------|
| `wezterm.lua` | Single-file Lua config: font, colors, tab bar, status bar, window, keybinds. |

## Activate

```bash
just apply wezterm
```

WezTerm live-reloads the config on save — no restart needed.

## Notable choices

- **Font** — `0xProto Nerd Font Mono` at 12pt with fallbacks
  (JetBrains Mono, Symbols Nerd Font, Noto Color Emoji); ligatures disabled.
- **Theme** — built-in `carbonfox` color scheme, with a custom tab-bar palette.
- **Live status bar** — left side shows a mode indicator (`N`/`C`/`S` with
  shifting color) plus color-coded RAM / CPU / GPU usage, polled from
  `/proc/meminfo`, `/proc/stat`, and `nvidia-smi` (GPU degrades to `--` without
  NVIDIA). Right side flashes a bell icon for 3s after a bell event.
- **Tab titles** — `<cwd-basename>: <process>`.
- **Keybinds** — `ctrl+alt`-based tab/split/scroll/search scheme, deliberately
  matching the [`ghostty`](ghostty.md) binds and avoiding tmux
  (prefix `Alt+a`) / vim-tmux-navigator (`Ctrl+hjkl`).
- **Background image** — pulls from `~/.dots/_wallpapers/` (not deployed; see
  [`_wallpapers`](../_wallpapers/README.md)); inactive panes dim via HSB.
- **`RESIZE` decorations** — borderless but still resizable; `WebGpu` front-end
  (often faster on Wayland); bells silenced (`audible_bell = Disabled`).
- WezTerm supports OSC 52 clipboard and the kitty/iTerm2 image protocols, which
  the [`tmux`](tmux.md) config relies on via `allow-passthrough`.
