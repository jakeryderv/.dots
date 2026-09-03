# shell

The shell configuration both bash and zsh share: environment, aliases,
functions, and the untracked machine-specific layer. Deploys as one directory
symlink at `~/.config/shell`; each shell's rc file sources the pieces it
wants, in the order it wants.

| File | Sourced | Contents |
| --- | --- | --- |
| `env.sh` | first | The Nix profile if the shell did not inherit it, then PATH, EDITOR, MANPAGER, ls colours. POSIX sh, so both shells read one file. |
| `functions.sh` | after the shell's own setup | `mkcd`, `up`. Written to run under both shells. |
| `aliases.sh` | after functions | Aliases. Anything needing a bash-only builtin is in the rc file instead. |
| `local.sh` | last | Machine-specific: CUDA, ROS, toolchain output dirs, secrets. **Untracked**; `local.sh.example` is the template. |

`link` mode is deliberate. `local.sh` is untracked, so a `tree` entry would
never deploy it; a directory symlink exposes whatever is in the directory,
which is what a file sourced at startup needs.

## Rule for the shared files

They run under bash and zsh alike. History, completion, keybindings, `shopt`,
and the `--bash` / `--zsh` flavour of a tool's hook belong in the rc file of
the shell that understands them — see [`bash.md`](bash.md) and [`zsh.md`](zsh.md). The gate lints
`env.sh` as POSIX sh and the other two as bash.

## Activate

```bash
dots apply shell
cp ~/.dots/config/shell/local.sh.example ~/.dots/config/shell/local.sh   # then edit
```

`dots apply bash` or `dots apply zsh` deploys the rc file that sources this.
Nothing here is loaded until an rc file does.

## local.sh

Per-machine layer, not committed. Hardcoded paths (the CUDA version), tools
that may be absent, secrets, or overrides of anything above. Installers like to
append to it; audit it occasionally against `env.sh`, which already puts
`~/.local/bin` and `~/.npm-global/bin` on `PATH` behind a duplication guard.
