# git

Global Git configuration. Deployed to `~/.gitconfig`.

See the root [README](../README.md) for shared deployment mechanics.

## Files

| File | Role |
|------|------|
| `.gitconfig` | Shared Git behavior, aliases, and defaults. |
| `.gitconfig.local.example` | Template for untracked identity, credentials, and machine-specific overrides. Not a manifest row, so never deployed. |

The tracked config includes `~/.gitconfig.local` last, so local scalar values
can override shared defaults. A missing local file is allowed.

## Activate

Create the local config before deploying on a new machine:

```bash
cp ~/.dots/home/gitconfig.local.example ~/.gitconfig.local
nvim ~/.gitconfig.local
just apply git
```

Because `~/.gitconfig` is a symlink into this repository, ordinary
`git config --global ...` commands edit the tracked file. Write machine-local
settings explicitly instead:

```bash
git config --file ~/.gitconfig.local user.name "Your Name"
git config --file ~/.gitconfig.local user.email "you@example.com"
```

After tools such as `gh auth setup-git` update global Git settings, review
`git diff` and move any machine-specific credential configuration into
`~/.gitconfig.local`.

## Verify

```bash
git config --global --includes --list --show-origin
dots status git
```

The explicit `--includes` makes `git config --global` show entries loaded from
`~/.gitconfig.local` as well as the tracked file.

## External dependencies

The **git binary** comes from [`flake.nix`](../flake.nix); apt's `/usr/bin/git`
stays installed for system packages that depend on it, and is shadowed on
`PATH`. See [`nix.md`](nix.md).

Not managed by this repo:

- **Git LFS** — needed by the tracked `filter.lfs` configuration when working
  with repositories that use LFS.
- **Neovim** — configured as the Git editor.
- **GitHub CLI** — needed when the local config uses `gh auth git-credential`.
  Comes from [`flake.nix`](../flake.nix). The helper must invoke bare `gh`, not
  an absolute path: a hardcoded `/usr/bin/gh` keeps resolving to an apt copy and
  silently pins Git auth to it.
