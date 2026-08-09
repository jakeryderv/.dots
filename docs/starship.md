# starship

[Starship](https://starship.rs) prompt config. Deployed to
`~/.config/starship.toml`.

See the root [README](../README.md) for shared deployment mechanics.

## Files

| File | Role |
|------|------|
| `.config/starship.toml` | Prompt format + per-module styling. |

## Activate

Deploying installs the config but does **not** enable the prompt. You must also:

1. Install starship (see [starship.rs](https://starship.rs)).
2. Enable it in [`_bash/local.sh`](../_bash/README.md) (machine-local, not
   committed):

   ```bash
   eval "$(starship init bash)"
   ```

```bash
just apply starship
```

## Notable choices

- **Two-line prompt** — context (user/host/dir/git/duration) on line one, the
  `❯` character on line two.
- **Carbonfox-matched** colors; git status uses Nerd Font glyphs (needs a
  [Nerd Font](fonts.md)).
- **Python module** shows only the active virtualenv (no version noise).
