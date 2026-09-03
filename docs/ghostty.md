# ghostty

[Ghostty](https://ghostty.org) terminal config. Deployed to `~/.config/ghostty/`.

See the root [README](../README.md) for shared deployment mechanics.

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
dots apply ghostty
```

Reload a running instance with the config-reload keybind (default
`ctrl+shift+,`) — no restart needed.

## Links, mouse, and clipboard

Mostly Ghostty defaults, documented here because
[`tmux`](tmux.md) depends on them and nothing in `config.ghostty`
mentions them.

- **Opening links** — `link-url` (default on) matches URLs on **`Ctrl`+hover**,
  then click; OSC 8 hyperlinks work the same way. `link-previews` shows the real
  destination on hover, which matters because OSC 8 lets the visible text differ
  from where the link goes.
- **`mouse-shift-capture = false`** (default, deliberately not overridden) — this
  is the load-bearing one. Holding `Shift` bypasses mouse reporting, so clicks
  reach Ghostty instead of the running program. Inside tmux (`mouse on`) that is
  the only way to reach Ghostty's link handler or its selection; tmux also binds
  `Ctrl+click` itself so the common case does not need `Shift`.
- **Clipboard** — `clipboard-write = allow` lets tmux copy out over OSC 52
  without a prompt; `clipboard-read = ask` still prompts before anything reads
  the clipboard. `copy-on-select` applies to Ghostty's own selections, not to
  selections made inside tmux.
- **Unbound but available** — `copy_url_to_clipboard` ships as an action with no
  default keybind, if yanking a URL beats opening it.

## Notable choices

- **Theme layering** — carbonfox stays pristine; all deviations live in
  `overrides.ghostty` so the theme can be re-vendored cleanly.
- **Startup directory** — new windows always open in `$HOME`
  (`working-directory = home`, `window-inherit-working-directory = false`);
  tabs and splits still inherit the current dir.
- **Background image** — pulls from `~/.dots/_wallpapers/` (not deployed; see
  [`_wallpapers`](../_wallpapers/README.md)).
- **No window decorations** + zero padding, matching the kitty/alacritty setups.
- **Keybinds — tabs yes, splits no.** Ghostty runs exactly two tabs, one for
  [`tmux`](tmux.md) and one for [`herdr`](herdr.md). That separation is the whole
  layout: splits and panes belong to the layer inside each tab, so Ghostty's own
  split bindings and the `ctrl+alt` scheme built on them were removed.

  | Kept | Released |
  |------|----------|
  | `ctrl+shift+t` / `ctrl+shift+w` — tab create/close (Ghostty defaults) | `ctrl+alt+*` — the old tab/split scheme and Ghostty's `ctrl+alt+arrow` splits |
  | `ctrl+tab` / `ctrl+shift+tab` — switch between the two tabs | `alt+1`–`alt+9` — `goto_tab` / `last_tab` |
  | `ctrl+shift+p` — command palette | |

  With only two tabs there is nothing for `alt+1..9` to do, which is what lets
  herdr keep them for indexed agent focus. Releasing them took **two** unbinds
  each: Ghostty binds the digits by logical key (`alt+1`) *and* by physical
  position (`alt+digit_1`), and releasing only the logical form leaves the other
  live.
- **Shell integration** — `ssh-env`/`ssh-terminfo` enabled so colors/keys work
  over SSH; `no-cursor` lets the block cursor apply at the prompt.
