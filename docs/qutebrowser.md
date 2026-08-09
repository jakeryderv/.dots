# qutebrowser

[qutebrowser](https://qutebrowser.org) config. Deployed to
`~/.config/qutebrowser/`.

See the root [README](../README.md) for shared deployment mechanics.

## Files

| File | Role |
|------|------|
| `config.py` | Python config: fonts, dark mode, hints, keybinds, etc. Calls `config.load_autoconfig(False)` so the GUI settings file is ignored and this file is the single source of truth. |

## Activate

```bash
just apply qutebrowser
```

Reload a running instance with `:config-source`.

## Install

qutebrowser itself is installed from source (for a newer Qt/QtWebEngine than
apt ships) via [`_helpers/install-qutebrowser.sh`](../_helpers/README.md).

## Notable choices

- **Font** — `0xProto Nerd Font Mono` at 12pt (ships in [`fonts`](fonts.md)).
- **Dark mode** — webpage darkening enabled (`lightness-cielab`).
- **Numeric hint chars** and hidden window decoration.
- `# ruff: noqa` / pyright pragmas at the top silence linter noise about the
  `c` and `config` objects qutebrowser injects at runtime.
