# bash

Modular bash configuration. `_init_.sh` sources each module in a defined
order; `~/.bashrc` just sources `_init_.sh`.

## Wiring

In `~/.bashrc`:

```bash
if [ -f "$HOME/.dots/_bash/_init_.sh" ]; then
    source "$HOME/.dots/_bash/_init_.sh"
fi
```

## Load order

`_init_.sh` sources modules explicitly (not via glob), so order is
controlled. Env first, then functions, then things that may reference them;
`local` is last so it can override anything above it.

```
exports → options → completions → functions → aliases → keybinds → llm → local
```

| Module             | Purpose                              | Tracked |
| ------------------ | ------------------------------------ | ------- |
| `exports.sh`       | PATH, EDITOR, LS_COLORS              | ✅      |
| `options.sh`       | history settings + shopt             | ✅      |
| `completions.sh`   | bash-completion + readline bindings  | ✅      |
| `functions.sh`     | shell functions                      | ✅      |
| `aliases.sh`       | aliases, isolated Playwright sessions, and OpenCode skill discovery guard | ✅      |
| `keybinds.sh`      | keybindings (may reference functions)| ✅      |
| `llm.sh`           | llm helper functions                 | ✅      |
| `local.sh`         | machine-specific config              | ❌ git-ignored |
| `local.sh.example` | template for `local.sh`              | ✅      |

Missing modules are skipped silently, so `local.sh` is optional.

## New machine

```bash
git clone <dots> ~/.dots
cp ~/.dots/_bash/local.sh.example ~/.dots/_bash/local.sh   # uncomment what applies
# then add the _init_.sh source block to ~/.bashrc
```

## Adding a module

1. Create `_bash/<name>.sh`.
2. Add `<name>` to the `bash_modules` array in `_init_.sh` (in the right spot).

## local.sh

Per-machine layer — not committed. Use it for hardcoded/machine-specific
paths (e.g. CUDA version), tools that may be absent (guard with
`command -v`), secrets, or overrides of a committed module. See
`local.sh.example`.
