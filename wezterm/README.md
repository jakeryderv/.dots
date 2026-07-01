# wezterm

[WezTerm](https://wezterm.org) terminal config. Stowed to `~/.config/wezterm/`.

See the root [README](../README.md) for shared stow mechanics.

## Files

| File | Role |
|------|------|
| `wezterm.lua` | Single-file Lua config: font, colors, tab bar, window, keybinds. |

## Activate

```bash
cd ~/.dots && stow wezterm
```

WezTerm live-reloads the config on save — no restart needed.

## Notable choices

- **Font** — `0xProto Nerd Font Mono` at 12pt with fallbacks
  (JetBrains Mono, Symbols Nerd Font, Noto Color Emoji); ligatures disabled.
- **Theme** — built-in `carbonfox` color scheme, with a custom tab-bar palette.
- **Background image** — pulls from `~/.dots/_wallpapers/` (not stowed; see
  [`_wallpapers`](../_wallpapers/README.md)).
- **`RESIZE` decorations** — borderless but still resizable.
- WezTerm supports OSC 52 clipboard and the kitty/iTerm2 image protocols, which
  the [`tmux`](../tmux/README.md) config relies on via `allow-passthrough`.
