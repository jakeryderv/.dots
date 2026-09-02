# shell

Modular bash configuration. `_init_.sh` sources each module in a defined
order; `~/.bashrc` just sources `_init_.sh`.

**Sourced, not deployed.** This is the only part of the repo that `just apply`
cannot install or repair — `~/.bashrc` lives outside the manifest, so the wiring
below is a manual step on each machine.

## Wiring

In `~/.bashrc`:

```bash
if [ -f "$HOME/.dots/shell/_init_.sh" ]; then
    source "$HOME/.dots/shell/_init_.sh"
else
    printf 'warning: %s missing; shell config NOT loaded\n' \
        "$HOME/.dots/shell/_init_.sh" >&2
fi
```

The `else` branch matters. With a bare `[ -f ]` test, moving or renaming this
directory does not fail — the shell simply starts with no aliases, exports,
functions, or keybinds, and says nothing about why. `just doctor` also checks
that `~/.bashrc` references this loader.

## Load order

`_init_.sh` sources modules explicitly (not via glob), so order is
controlled. Env first, then functions, then things that may reference them;
`local` is last so it can override anything above it.

```
exports → options → completions → functions → aliases → keybinds → tools → llm → local
```

| Module             | Purpose                              | Tracked |
| ------------------ | ------------------------------------ | ------- |
| `exports.sh`       | PATH, EDITOR, LS_COLORS              | ✅      |
| `options.sh`       | history settings + shopt             | ✅      |
| `completions.sh`   | bash-completion + readline bindings  | ✅      |
| `functions.sh`     | shell functions                      | ✅      |
| `aliases.sh`       | aliases and isolated Playwright sessions                                  | ✅      |
| `keybinds.sh`      | keybindings (may reference functions)| ✅      |
| `tools.sh`         | fzf, starship, direnv shell integrations | ✅      |
| `local.sh`         | machine-specific config              | ❌ git-ignored |
| `local.sh.example` | template for `local.sh`              | ✅      |

`local.sh` is the only optional module: a missing one is skipped, while any
other missing module warns on stderr, since a shell without `exports.sh` or
`aliases.sh` starts degraded rather than merely plain.

## New machine

```bash
git clone <dots> ~/.dots
cp ~/.dots/shell/local.sh.example ~/.dots/shell/local.sh   # uncomment what applies
# then add the _init_.sh source block to ~/.bashrc
```

## Adding a module

1. Create `shell/<name>.sh`.
2. Add `<name>` to the `bash_modules` array in `_init_.sh` (in the right spot).

## local.sh

Per-machine layer — not committed. Use it for hardcoded/machine-specific
paths (e.g. CUDA version), tools that may be absent (guard with
`command -v`), secrets, or overrides of a committed module. See
`local.sh.example`.

Installers append to it. Audit it occasionally: `exports.sh` already puts
`~/.local/bin` and `~/.npm-global/bin` on `PATH` behind a duplication guard, so
an unguarded copy added here is redundant, and enough of them make it unclear
which of two managers a binary resolves from.
