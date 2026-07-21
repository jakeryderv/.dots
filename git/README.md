# git

Global Git configuration. Stowed to `~/.gitconfig`.

See the root [README](../README.md) for shared stow mechanics.

## Files

| File | Role |
|------|------|
| `.gitconfig` | Shared Git behavior, aliases, and defaults. |
| `.gitconfig.local.example` | Template for untracked identity, credentials, and machine-specific overrides. Ignored by Stow. |

The tracked config includes `~/.gitconfig.local` last, so local scalar values
can override shared defaults. A missing local file is allowed.

## Activate

Create the local config before stowing on a new machine:

```bash
cp ~/.dots/git/.gitconfig.local.example ~/.gitconfig.local
nvim ~/.gitconfig.local
cd ~/.dots && stow git
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

Not managed by Stow:

- **Git LFS** — needed by the tracked `filter.lfs` configuration when working
  with repositories that use LFS.
- **Neovim** — configured as the Git editor.
- **GitHub CLI** — needed when the local config uses `gh auth git-credential`.
