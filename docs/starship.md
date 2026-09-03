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

Nothing else. The binary comes from [`flake.nix`](../flake.nix) and
[`shell/tools.sh`](../shell/README.md) runs `starship init bash`, so a machine
that has run `nix profile add` and wired `shell/` into `~/.bashrc` gets the
prompt on the next shell.

starship previously lived at `/usr/local/bin/starship`, put there by
starship.rs' curl installer with nothing tracking it; that copy is left in
place but shadowed. The init line used to be a manual step in `local.sh`.

## Notable choices

- **Two-line prompt** — context (user/host/dir/git/duration) on line one, the
  `❯` character on line two.
- **Carbonfox-matched** colors; git status uses Nerd Font glyphs (needs a
  [Nerd Font](fonts.md)).
- **Python module** shows only the active virtualenv (no version noise).
