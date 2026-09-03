# config/

One directory per package. Where each one deploys is stated in the repo-root
[`dots.toml`](../dots.toml), never inferred from the path: `config/nvim` goes to
`~/.config/nvim` and `config/git/gitconfig` to `~/.gitconfig` because its table
says so.

## Rule for this tree

**A package directory contains only deployable content.** Files are enumerated
with `git ls-files`, so anything tracked inside `config/<name>/` is a candidate
for deployment. That is what lets `.gitignore` be the repo's only ignore list.

Consequently, documentation does **not** live here. Per-package notes are in
[`docs/`](../docs/README.md) as `docs/<name>.md`. The one tolerated exception
is a `*.example` file beside a single-file source, such as
`config/git/gitconfig.local.example`: the `git` table names the file, not the
directory, so the example is never deployed.

This file is a sibling of the packages, not inside one, so it is never
deployed.

## Adding a package

1. `mkdir config/<name>/` and put the files in it.
2. Add `[packages.<name>]` to `dots.toml`, choosing `link` or `tree` (see the
   header there).
3. Write `docs/<name>.md`.
4. `dots plan <name>` to preview, then `dots apply <name>`.
