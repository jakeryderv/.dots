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

## Status while both tools coexisted

**`just status` is the authority.**

While both tools coexisted, `dots status` reported false positives as soon as
`config/` existed: it discovered `config/` and `docs/` as stow packages and
expected `~/alacritty/alacritty.toml` and `~/alacritty.md`. That noise grew with
each package moved — by the end it read `0/144` — and vanished when stow was
removed in phase 3. It never meant anything was broken.

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

**Complete.** All three phases are done.

- **Phase 1** — manifest written against the old stow layout and validated
  against `dots status` before any file moved. Both agreed on 118 files.
- **Phase 2** — all 23 rows moved to the flat XDG layout, one package at a time.
- **Phase 3** — stow removed: `.stowrc`, `_dots/bin/dots`, `setup.sh`, and the
  `stow` line in CI are gone.

`just status` reports 23 rows matching, 0 topology drift, 0 problems, and
`REQUIRE_LINTERS=1 _helpers/check-repo.sh` passes.

### What replaced what

| Removed | Replacement |
| --- | --- |
| `stow` / `dots stow --apply` | `just apply` |
| `dots status` | `just status` (reads the manifest) |
| `dots diff` | `just diff` (reuses the deployer's pair expansion) |
| `dots doctor` | `just doctor` → `_dots/bin/doctor.sh` |
| `dots deps` | `just deps` → `_dots/bin/deps.sh` |
| `.stowrc` ignore patterns | `.gitignore`, via the `git ls-files` enumerator |
| `is_ignored()` stow-semantics shim | deleted; nothing to keep in sync |
| `setup.sh` linking the CLI | `bin/dots`, a normal deployed script |
| `--no-folding` flags in four docs | the manifest's `MODE` column |

`bin/dots` is worth calling out: the entrypoint used to be a symlink created by
a bootstrap script that existed only for that purpose. It is now an ordinary
script deployed by the same manifest rows as everything else in `bin/`, so
`setup.sh` had nothing left to do.

### Checks added along the way

The migration kept surfacing gates that passed while verifying nothing, so two
were added to `_helpers/check-repo.sh`:

- **Manifest validation** — every row's mode is known, its source exists and has
  tracked files, and its target is rooted at `$HOME`, `$XDG_CONFIG_HOME`, or
  `$XDG_DATA_HOME`. A typo in the manifest is otherwise a silent no-op at apply
  time, since a nonexistent source simply contributes zero files.
- **Path-list existence guard** — `BASH_PATHS` and `LUA_PATHS` are checked
  before use. `find` reports a missing path on stderr and keeps going, and these
  traversals feed process substitutions whose exit status is discarded, so a
  stale entry silently shrank the lint surface. This bit twice: the Lua check
  ran `find nvim wezterm` and passed while checking zero files, and `setup.sh`
  lingered in `BASH_PATHS` after deletion.

Both were negative-tested rather than assumed.
