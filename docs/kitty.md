# kitty

[kitty](https://sw.kovidgoyal.net/kitty/) terminal config. Deployed to
`~/.config/kitty/`.

See the root [README](../README.md) for shared deployment mechanics.

## Files

| File | Role |
|------|------|
| `kitty.conf` | Single-file config: font, cursor, scrollback, window, plus a vendored carbonfox color scheme. |

## Activate

```bash
just apply kitty
```

Reload a running instance with `ctrl+shift+f5`.

## Notable choices

- **Font** — `0xProto Nerd Font Mono` at 12pt (ships in [`fonts`](fonts.md)),
  ligatures disabled.
- **Theme** — carbonfox palette vendored inline from the nightfox upstream.
- **No decorations**, slight transparency (`background_opacity 0.97`).
- **`ctrl+shift+t` disabled** (`no_op`) to avoid conflicting with tmux.
- **Kitty graphics protocol** is what [`herdr`](herdr.md) forwards from pane
  applications (`kitty_graphics = true`).
