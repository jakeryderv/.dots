# Migration: stow → manifest

Moving from GNU Stow to the manifest-driven deployer in
[`_dots/bin/link.sh`](../_dots/bin/link.sh), one package at a time, with a
working machine and a green CI at every step.

## Why

Stow decides two things implicitly, and both turned out to be wrong here:

- **Package discovery.** Any top-level directory is deployment surface. Adding
  a tooling directory named `just/` immediately produced a phantom target at
  `~/link.sh`.
- **Folding.** Stow links a whole directory when the target does not exist yet,
  and links file-by-file when it does — so the shape of a deployment depends on
  what order things happened to be created on the machine, not on intent. This
  repo had 13 unfolded targets while only four package READMEs mentioned
  `--no-folding`, and inside `~/.claude` alone folding had landed at three
  different depths (`hooks/` folded, `skills/` not, `skills/project-status/`
  folded).

The manifest declares both. `PKG` and `MODE` are columns, not inferences.

## Status during migration

**From the first migrated package onward, `just status` is the authority.**

`dots status` starts reporting false positives as soon as `config/` exists,
because it discovers `config/` and `docs/` as stow packages and expects
`~/alacritty/alacritty.toml` and `~/alacritty.md`. That noise grows with each
package moved and disappears in phase 3 when stow is removed. It does not mean
anything is broken — cross-check with `just status`, which reads the manifest.

## Per-package recipe

Worked example: `alacritty`, the first package migrated.

### 1. Record the pre-state

```bash
just status alacritty
git ls-files alacritty
ls -la ~/.config/alacritty
```

### 2. Move the repo side

```bash
git mv alacritty/.config/alacritty config/alacritty
git mv alacritty/README.md docs/alacritty.md
rmdir -p alacritty/.config          # drop the now-empty package shell
```

Git records both as renames (`R` in `git status --short`), so history follows
the files.

Destination by kind:

| Old | New |
| --- | --- |
| `<pkg>/.config/<pkg>/` | `config/<pkg>/` |
| `<pkg>/.local/share/<x>/` | `data/<x>/` |
| `<pkg>/.local/bin/` | `bin/` |
| `<pkg>/.<file>` | `home/<file>` (no leading dot) |
| `<pkg>/.<dir>/` | `home/<dir>/` (no leading dot) |
| `<pkg>/README.md` | `docs/<pkg>.md` |

### 3. Update the manifest row

Point `SOURCE` at the new path. Leave `PKG`, `MODE`, and `TARGET` alone.

```diff
-alacritty  link  alacritty/.config/alacritty  $XDG_CONFIG_HOME/alacritty
+alacritty  link  config/alacritty             $XDG_CONFIG_HOME/alacritty
```

### 4. Collapse the target if it is unfolded

`just plan <pkg>` reports `unfolded` when the target is a real directory that
should be a single symlink. The move in step 2 leaves the old links dangling,
so the directory must be removed before the new link can be made.

**Verify before deleting.** The check is that the directory contains nothing but
symlinks — removing a symlink never touches what it points at:

```bash
find ~/.config/<pkg> -mindepth 1 -not -type l     # must print nothing
rm ~/.config/<pkg>/*                              # symlinks only
rmdir ~/.config/<pkg>                             # fails loudly if anything remains
```

`rmdir` rather than `rm -rf` on purpose: it refuses to remove a non-empty
directory, so an unexpected real file stops the migration instead of vanishing.

Packages already reporting `ok` in `just status` skip this step entirely.

### 5. Relink and verify

```bash
just plan alacritty     # expect: link ~/.config/alacritty, 0 conflicts
just apply alacritty
```

Three checks, not one — the link existing does not prove it resolves:

```bash
ls -ld ~/.config/alacritty                        # is a symlink into ~/.dots
head -3 ~/.config/alacritty/alacritty.toml        # content readable through it
readlink -f ~/.config/alacritty/alacritty.toml    # resolves into the repo
```

### 6. Confirm nothing else regressed

```bash
just status     # drift count drops by one, problems stays 0
just check      # repository gate still green
```

## Special cases

**Targets holding third-party content.** `~/.claude/skills/` and
`~/.pi/agent/skills/` contain symlinks this repo does not own —
`gh` and `playwright-cli`, installed by `_helpers/`. Before deleting anything
in a target, classify each link by where it resolves:

```bash
for l in ~/.claude/skills/*; do
  [ -L "$l" ] || continue
  case "$(readlink -f "$l")" in
    "$HOME/.dots"/*) echo "REPO     $l";;
    *)               echo "EXTERNAL $l";;
  esac
done
```

Only the `REPO` ones dangle after a move and need replacing. Left alone, the
external ones keep working.

**Relative symlinks inside the repo.** `home/agent-skills/claude/skills/`
contains links into `home/agent-skills/agents/skills/`. Renaming `.agents` to
`agents` broke their relative targets, silently — `git mv` does not rewrite link
contents. Check with `[ -e "$link" ]` after any move that renames a directory a
tracked symlink points through.

## Gotchas found while migrating

- **`just apply <pkg>` silently did nothing** the first time, reporting
  `0 link(s) in scope`. The package name had been derived from the first path
  segment of `SOURCE`, which in the flat layout is the XDG category (`config`),
  not the package. Fixed by making `PKG` an explicit manifest column. If a
  filtered command reports 0 rows in scope, check the `PKG` column first.
- **The same path-prefix inference bug recurred** in
  `_helpers/verify-readmes.sh`, which classified `config/` as a manifest source
  because `config/nvim` starts with it — vacuously skipping the check it was
  supposed to perform. Compare whole paths, not leading segments.
- **Docs cannot live inside a source directory.** `git ls-files` is the file
  enumerator, so a `README.md` inside `config/<pkg>/` would deploy to
  `~/.config/<pkg>/README.md`. `bin/` is itself a manifest source, so it can
  carry no README at all — which forced the `verify-readmes.sh` rewrite from
  "a README per top-level dir" to "a `docs/<pkg>.md` per manifest package, and a
  README for every directory that is not itself a source".
- **Helpers and tests hardcode layout paths.** Six files referenced the old
  package paths (`_helpers/check-repo.sh`, `verify-agent-skills.sh`,
  `install-delta.sh`, `install-playwright-cli.sh`, and both test scripts). Two
  of them failed *open* rather than loudly: the Lua check ran
  `find nvim wezterm` and passed while checking zero files. Grep for the old
  paths rather than waiting for the gate to fail:
  `grep -rnE '<pkg>/\.' _helpers/ _dots/`

## Status

**Phases 1 and 2 are complete.** All 23 manifest rows are in the flat layout;
`just status` reports 23 matching, 0 topology drift, 0 problems, and
`just check` is green.

**Phase 3 is outstanding.** Stow is no longer used, but its remnants remain and
`dots status` now reports `0/144` — it rediscovers `config/`, `home/`, `data/`,
and `bin/` as stow packages and expects them in `$HOME`. That is noise, not
breakage; `just status` is the authority. Remaining work:

- Delete `.stowrc` and the stow code paths in `_dots/bin/dots` (`stow_cmd`,
  `stow_check_cmd`, `is_ignored`, `status_cmd`, the folding flags). What is
  worth keeping from that script is `doctor` and `deps`, which check shell
  wiring and installed tools rather than links.
- Drop `stow` from the CI apt line in `.github/workflows/ci.yml`.
- Decide whether `setup.sh` still needs to link the `dots` CLI into
  `~/.local/bin`, now that `just` is the entry point.
- Optionally fold `_helpers/` into `tools/` behind `just install <tool>`.
- Bulk moves go in their own commit, listed in `.git-blame-ignore-revs`, per the
  existing convention.

Done in phase 2 rather than deferred: `_helpers/verify-readmes.sh` was rewritten
to check the manifest, because `bin/` cannot carry a README.
