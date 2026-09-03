# alacritty

[Alacritty](https://alacritty.org) terminal config. Deployed to
`~/.config/alacritty/`.

See the root [README](../README.md) for shared deployment mechanics.

## Files

| File | Role |
|------|------|
| `alacritty.toml` | Single-file config: window, font, cursor, scrolling, plus a vendored carbonfox color scheme. |

## Activate

```bash
dots apply alacritty
```

Alacritty live-reloads the config on save — no restart needed.

## Notable choices

- **Font** — `0xProto Nerd Font Mono` at 12pt (ships in [`fonts`](fonts.md)).
- **Theme** — carbonfox palette vendored inline from the nightfox upstream.
- **No decorations**, zero padding, slight transparency (`opacity = 0.97`) to
  match the kitty/ghostty setups.
