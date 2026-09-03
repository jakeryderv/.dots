# _dots

Repo-local tooling for managing this dotfiles repository.

**Not a package.** This directory is underscore-prefixed by convention and,
more to the point, is not named in [`dots.toml`](../dots.toml) — so nothing
here is ever deployed.

## Contents

| Path | Purpose |
| --- | --- |
| `dots.py` | The `dots` tool: deployer, validator, doctor, and the CLI around them. Standard library only. |
| `checks/check-repo.sh` | The repo gate, and what CI runs. Portable: never inspects `$HOME` or live targets. |
| `tests/test_dots.py` | Behaviour tests for `dots.py`, run by the gate. |

`checks/` validates the repository; [`tools/`](../tools/README.md) provisions
software on the machine. They were one directory until the split, which made
`tools/` mean two things at once.

The line between the gate and `dots doctor` is what they are allowed to look
at: the gate reads only the repo, so CI can run it on a bare checkout, while
`doctor` inspects the live machine — `$HOME`, shell wiring, deployed links,
flake binaries shadowed on `PATH`.

The `dots` command on `PATH` is [`pkgs/scripts/dots`](../pkgs/scripts/dots), a
three-line wrapper that finds the repo and execs `dots.py`, so every command
below works from any directory. On a fresh machine, before that link exists,
`python3 _dots/dots.py <command>` is the same thing.

## Commands

```bash
dots status          # every entry: does the target resolve into the repo?
dots plan            # dry-run every entry (never mutates)
dots apply           # create or repoint symlinks
dots plan vim        # scope any of these to one package
dots diff            # content differences for targets that drifted
dots unlink          # remove symlinks that resolve into this repo
dots validate        # dots.toml and the documentation rules (repo only)
dots check           # the full gate CI runs
dots doctor          # health checks against this machine
dots deps            # required/optional external command check
dots packages        # package names dots.toml knows about
dots tools           # installers under tools/
dots install NAME    # run tools/install-NAME.sh
```

`dots --help` lists them; `dots` alone is `dots status`.

## Design notes

Two decisions carry most of the weight, both reactions to how GNU Stow behaved
before the migration:

- **`git ls-files` is the file enumerator.** `.gitignore` is therefore the only
  ignore list in the repo. There is no second ignore syntax, and no
  compatibility shim to keep the two agreeing.
- **Nothing is inferred.** `dots.toml` declares the mode, and the package name
  is the table key. Deriving either from a path was tried, and produced silent
  no-ops when the layout changed underneath it.

Two more are enforced rather than documented:

- **A real file at a target is a conflict.** `apply` reports it and moves on;
  it never overwrites. A stale symlink is repointed, because a symlink carries
  no content to lose.
- **An unknown package name is an error.** Filtering to a name that matches
  nothing would turn any command into a silent no-op, so `dots plan nosuchpkg`
  exits 2 instead.

Inside `dots.py`, `Repo.pairs()` is the one expansion from a manifest entry to
concrete (source, target) symlinks, and every command consumes it. Adding a
command means adding a consumer, not another traversal.

## Testing

```bash
python3 -m unittest discover -s _dots/tests
```

The tests build a throwaway fixture repo with its own `dots.toml` and git
history, then drive the real CLI against a scratch `$HOME`: both modes,
`links` fan-out, untracked-file exclusion, idempotent apply, package filtering,
conflict refusal, stale-link repointing, selective unlink, and every
`validate` rule. `ruff check` and `ruff format --check` gate the Python the
way `shfmt` and `stylua` gate the other languages; `ruff.toml` at the root is
the one config both the editor and the gate read.
