# data/

Deployable files that land under `$XDG_DATA_HOME` (default `~/.local/share`) —
application data rather than configuration.

The layout mirrors the destination: `data/fonts/` deploys to
`~/.local/share/fonts/`, `data/bash-completion/completions/` to
`~/.local/share/bash-completion/completions/`. See the repo-root
[`manifest`](../manifest) for the authoritative rows.

## Why these are `tree` mode

Both targets are **shared with other installers** — a font installed by apt and
a completion shipped by a package both land in the same directories. `link` mode
would replace the whole directory with a symlink into this repo and hide
everything the system put there.

`tree` mode creates real directories and links only the tracked files, so this
repo's contents coexist with everything else instead of displacing it.

## Rule for this tree

Same as `config/` and `home/`: **a source directory contains only deployable
content**, because files are enumerated with `git ls-files`. Documentation lives
in [`docs/`](../docs/README.md) as `docs/<pkg>.md`.

This file is a sibling of the sources (`data/fonts`,
`data/bash-completion/completions`), not inside one, so it is never deployed.

## Related

Executables go to `~/.local/bin` from [`bin/`](../bin), which is a manifest
source and therefore carries no README of its own — see
[`docs/scripts.md`](../docs/scripts.md).
