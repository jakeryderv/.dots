# fonts

Nerd Fonts. Deployed to `~/.local/share/fonts/`.

See the root [README](../README.md) for shared deployment mechanics.

## What's here

The [0xProto Nerd Font](https://github.com/0xType/0xProto) family (patched with
Nerd Font glyphs), in three variants:

| Variant | Files | Used by |
|---------|-------|---------|
| Mono | `0xProtoNerdFontMono-*.ttf` | terminals, editor (fixed advance width) |
| Propo | `0xProtoNerdFontPropo-*.ttf` | proportional-spacing contexts |
| (default) | `0xProtoNerdFont-*.ttf` | the base patched font |

Every config in this repo that sets a font uses `0xProto Nerd Font Mono`.

## Activate

```bash
dots apply fonts
fc-cache -f ~/.local/share/fonts     # refresh the font cache
fc-match '0xProto Nerd Font Mono'    # confirm it resolves
```

The `fc-cache` step is required — symlinking the files isn't enough; the cache
must be rebuilt before apps can see them.
