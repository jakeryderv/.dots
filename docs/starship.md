# starship

[Starship](https://starship.rs) prompt config. Deployed to
`~/.config/starship.toml`.

See the root [README](../README.md) for shared deployment mechanics.

## Files

| File | Role |
|------|------|
| `.config/starship.toml` | Prompt format + per-module styling. |

## Activate

```bash
dots apply starship
```

Install the binary using the [official installer](software.md#editor-and-shell-tools)
with `--bin-dir "$HOME/.local/bin"`. The tracked Bash and Zsh rc files run
`starship init` for their respective shells, so the prompt appears in a fresh
shell after installation and `dots apply`. Do not add another init hook to
`local.sh`.

## Notable choices

- **Two-line prompt** — context (user/host/dir/git/duration) on line one, the
  `❯` character on line two.
- **Carbonfox-matched** colors; git status uses Nerd Font glyphs (needs a
  [Nerd Font](fonts.md)).
- **Python module** shows only the active virtualenv (no version noise).
