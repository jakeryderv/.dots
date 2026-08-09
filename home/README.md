# home/

Deployable configuration for tools that **do not** respect the XDG Base
Directory spec. Everything here lands directly in `$HOME` as a dotfile or
dotdirectory.

Names are stored without their leading dot — `home/gitconfig` deploys to
`~/.gitconfig`, `home/claude/` to `~/.claude/`. The dot belongs to the
destination, and the repo-root [`manifest`](../manifest) states it explicitly in
the TARGET column. Storing them undotted keeps the tree visible to `ls`, `find`,
and shell globs without special-casing.

The size of this directory is a rough measure of how much software in the
toolchain still ignores XDG. It should shrink over time, not grow: prefer
[`config/`](../config/README.md) whenever a tool supports it.

## Rule for this tree

Same as `config/`: **a source directory contains only deployable content**,
because files are enumerated with `git ls-files`. Documentation lives in
[`docs/`](../docs/README.md) as `docs/<pkg>.md`.

Files that are templates rather than deployments — `gitconfig.local.example`,
for instance — sit at this level rather than inside a source directory, so they
are never enumerated and never deployed.

## Note on the agent trees

`home/claude/` and `home/agent-skills/claude/` both deploy into `~/.claude/`.
They are separate manifest rows in `tree` mode, so each links only its own files
and the two never interact. Under stow this arrangement required `--no-folding`
on both packages to avoid a race.

`home/agent-skills/claude/skills/` holds relative symlinks into
`home/agent-skills/agents/skills/`, so the canonical skill content exists once
and is shared by both agent trees.
