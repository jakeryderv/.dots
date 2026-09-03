# pkgs/

One directory per package. Where each one deploys is stated in the repo-root
[`manifest`](../dots.toml), never inferred from the path: `pkgs/nvim` goes to
`~/.config/nvim` and `pkgs/git/gitconfig` to `~/.gitconfig` because the
manifest says so.

## Rule for this tree

**A package directory contains only deployable content.** Files are enumerated
with `git ls-files`, so anything tracked inside `pkgs/<name>/` is a candidate
for deployment. That is what lets `.gitignore` be the repo's only ignore list.

Consequently, documentation does **not** live here. Per-package notes are in
[`docs/`](../docs/README.md) as `docs/<name>.md`. The one tolerated exception
is a `*.example` file beside a single-file source, such as
`pkgs/git/gitconfig.local.example`: the manifest row names the file, not the
directory, so the example is never deployed.

This file is a sibling of the packages, not inside one, so it is never
deployed.

## Adding a package

1. `mkdir pkgs/<name>/` and put the files in it.
2. Add a manifest row, choosing `link` or `tree` (see the manifest header).
3. Write `docs/<name>.md`.
4. `just plan <name>` to preview, then `just apply <name>`.
