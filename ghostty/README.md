# ghostty

[Ghostty](https://ghostty.org) terminal config. Stowed to `~/.config/ghostty/`.

See the root [README](../README.md) for shared stow mechanics.

## Files

Ghostty processes `config-file` includes at the *end* of the parent file, in the
order listed, and an included file overrides the parent. The load order is
chosen so the theme is faithful and local tweaks always win:

| File | Role |
|------|------|
| `config.ghostty` | Main config. Includes the theme, then the overrides file (in that order). |
| `carbonfox.ghostty` | Vendored carbonfox palette (kept byte-for-byte faithful to the nightfox upstream). |
| `overrides.ghostty` | Tracked tweaks loaded **after** the theme, so values here beat it (e.g. `cursor-color`, startup directory). |

Only `config.ghostty` is read directly by Ghostty; it pulls in the other two via
`config-file =`.

## Activate

```bash
cd ~/.dots && stow ghostty
```

Reload a running instance with the config-reload keybind (default
`ctrl+shift+,`) — no restart needed.

## Notable choices

- **Theme layering** — carbonfox stays pristine; all deviations live in
  `overrides.ghostty` so the theme can be re-vendored cleanly.
- **Startup directory** — new windows always open in `$HOME`
  (`working-directory = home`, `window-inherit-working-directory = false`);
  tabs and splits still inherit the current dir.
- **Background image** — pulls from `~/.dots/_wallpapers/` (not stowed; see
  [`_wallpapers`](../_wallpapers/README.md)).
- **No window decorations** + zero padding, matching the kitty/alacritty setups.
- **Keybinds** — `ctrl+alt`-based tab/split scheme chosen to avoid clashing with
  tmux (prefix `Alt+a`) and vim-tmux-navigator (`Ctrl+hjkl`). New/close tab use
  `Ctrl+Alt+C`/`Ctrl+Alt+Shift+X`, replacing Ghostty's default
  `Ctrl+Shift+T`/`Ctrl+Shift+W` bindings.
- **Shell integration** — `ssh-env`/`ssh-terminfo` enabled so colors/keys work
  over SSH; `no-cursor` lets the block cursor apply at the prompt.
