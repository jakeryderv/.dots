# config/

Deployable configuration for tools that respect the XDG Base Directory spec.
Everything here lands under `$XDG_CONFIG_HOME` (default `~/.config`).

Each subdirectory is a **source** named in the repo-root [`manifest`](../manifest),
which is the single source of truth for what deploys where. Nothing in this tree
is deployed unless a manifest row names it.

## Rule for this tree

**A source directory contains only deployable content.** Files are enumerated
with `git ls-files`, so anything tracked inside `config/<pkg>/` ends up in
`~/.config/<pkg>/`. That is what lets `.gitignore` be the repo's only ignore
list — there is no second ignore syntax and no exclusion rules to maintain.

Consequently, documentation does **not** live here. Per-package notes are in
[`docs/`](../docs/README.md) as `docs/<pkg>.md`.

This file is a sibling of the sources, not inside one, so it is never deployed.

## Adding a package

1. `mkdir config/<pkg>/` and put the config files in it.
2. Add a row to the [`manifest`](../manifest), choosing `link` or `tree`
   (see the manifest header for which to pick).
3. Write `docs/<pkg>.md`.
4. `just plan <pkg>` to preview, then `just apply <pkg>`.
