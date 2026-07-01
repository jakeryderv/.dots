# alacritty

[Alacritty](https://alacritty.org) terminal config. Stowed to
`~/.config/alacritty/`.

See the root [README](../README.md) for shared stow mechanics.

## Files

| File | Role |
|------|------|
| `alacritty.toml` | Single-file config: window, font, cursor, scrolling, plus a vendored carbonfox color scheme. |

## Activate

```bash
cd ~/.dots && stow alacritty
```

Alacritty live-reloads the config on save — no restart needed.

## Notable choices

- **Font** — `0xProto Nerd Font Mono` at 12pt (ships in [`fonts`](../fonts/README.md)).
- **Theme** — carbonfox palette vendored inline from the nightfox upstream.
- **No decorations**, zero padding, slight transparency (`opacity = 0.97`) to
  match the kitty/ghostty setups.
