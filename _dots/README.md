# _dots

Repo-local tooling for managing this dotfiles repository.

**Not a manifest package.** This directory is underscore-prefixed by convention
and, more to the point, is not named in the [`manifest`](../manifest) — so
nothing here is ever deployed.

## Contents

| Path | Purpose |
| --- | --- |
| `bin/link.sh` | The deployer. Reads the manifest and creates the symlinks it declares. |
| `bin/doctor.sh` | Live-machine health: shell wiring, deployed entrypoint, link state. |
| `bin/deps.sh` | Reports which expected tools are installed. |
| `checks/check-repo.sh` | The repo gate, and what CI runs. Portable: never inspects `$HOME` or live targets. |
| `checks/verify-readmes.sh` | Every manifest package has `docs/<pkg>.md`; every non-source top-level directory has a `README.md`. |
| `tests/` | Behaviour tests, run by `just check`. |

`checks/` validates the repository; [`tools/`](../tools/README.md) provisions
software on the machine. They were one directory until the split, which made
`tools/` mean two things at once.

The line between `checks/` and `bin/doctor.sh` is what they are allowed to look
at: `checks/` reads only the repo, so CI can run it on a bare checkout, while
`doctor.sh` inspects the live machine — `$HOME`, shell wiring, deployed links.

The user-facing entrypoint is the repo-root [`justfile`](../justfile). The
`dots` command in [`bin/`](../bin) is a thin wrapper that points `just` back at
it, so the commands below work from any directory.

## Common commands

```bash
dots status          # every manifest row: does the target resolve into the repo?
dots plan            # dry-run all rows (never mutates)
dots apply           # create or repoint symlinks
dots plan vim        # scope any command to one package
dots diff            # content differences for targets that drifted
dots unlink          # remove symlinks that resolve into this repo
dots doctor          # live-machine health checks
dots check           # portable syntax/parser/lint/behaviour checks (CI-safe)
dots deps            # required/optional external command check
```

Run `dots` with no arguments for the full recipe list.

## Design notes

Two decisions carry most of the weight, both reactions to how GNU Stow behaved
before the migration:

- **`git ls-files` is the file enumerator.** `.gitignore` is therefore the only
  ignore list in the repo. There is no second ignore syntax, and no
  compatibility shim to keep the two agreeing.
- **Nothing is inferred.** The manifest declares the package name and the link
  topology. Deriving either from a path was tried, and produced silent no-ops
  when the layout changed underneath it.

`link.sh` has one expansion function — manifest row to concrete
(source, target) pairs — and every command consumes it. Adding a command means
adding a consumer, not another traversal.

## Testing

```bash
bash _dots/tests/run.sh
```

`tests/link-test.sh` builds a throwaway fixture repo with its own manifest and
git history, then exercises `link.sh` against a scratch `$HOME`: both modes,
untracked-file exclusion, idempotent apply, package filtering, conflict
refusal, and selective unlink.
