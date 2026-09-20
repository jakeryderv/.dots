# git

Global Git configuration. Deployed to `~/.gitconfig`.

See the root [README](../README.md) for shared deployment mechanics.

## Files

| File | Role |
|------|------|
| `.gitconfig` | Shared Git behavior, aliases, and defaults. |
| `.gitconfig.local.example` | Template for untracked identity, credentials, and machine-specific overrides. The `git` entry in `dots.toml` names `gitconfig` alone, so this is never deployed. |

The tracked config includes `~/.gitconfig.local` last, so local scalar values
can override shared defaults. A missing local file is allowed.

## Activate

Create the local config before deploying on a new machine:

```bash
cp ~/.dots/config/git/gitconfig.local.example ~/.gitconfig.local
nvim ~/.gitconfig.local
dots apply git
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

The **Git binary** comes from the `git-core/ppa` apt repository recommended by
Git's official Ubuntu installation guide. GitHub CLI uses its official apt
repository, and Delta uses its official `.deb` release. See the
[software inventory](software.md#everyday-cli-tools) for setup and updates.

Other dependencies:

- **Git LFS** — needed by the tracked `filter.lfs` configuration when working
  with repositories that use LFS; remains a system package.
- **Neovim** — configured as the Git editor; installed from an official release.
- **GitHub CLI** — needed when the local config uses `gh auth git-credential`.
  Keep the helper as bare `gh` so PATH selects the installed copy. Existing
  credentials stay in their normal locations and do not need reauthorization.
