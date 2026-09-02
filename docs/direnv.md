# direnv

Global [direnv](https://direnv.net/) extensions - shared helper functions for
per-directory environments. direnv itself is hooked into bash from
[`shell/local.sh`](../shell/README.md) (`eval "$(direnv hook bash)"`), not from
this package.

## Tracked

| File | Purpose |
| --- | --- |
| `.config/direnv/direnvrc` | `use_gh_account` - pin the gh CLI to a specific GitHub account per directory tree; sources `nix-direnv` for `use flake` |

`direnvrc` is sourced before every `.envrc`, so its functions need no
`source_env`. direnv watches the file: editing it invalidates cached
environments, and the next `cd` into a direnv directory re-evaluates.

## Per-project toolchains with `use flake`

`direnvrc` sources [nix-direnv](https://github.com/nix-community/nix-direnv)
(installed by [`flake.nix`](../flake.nix)), which adds `use flake`, caches the
evaluation so a `cd` is not a full re-eval, and registers the resulting store
paths as GC roots so `nix store gc` cannot collect a shell still in use.

A project pins its own toolchain with a `flake.nix` plus a one-line `.envrc`:

```bash
echo 'use flake' > .envrc && direnv allow
```

`pi-cli-tools` uses this to get Node 22 where the global toolchain ships 24.
Add `.direnv/` to the project's `.gitignore` - it holds the GC roots.

The guard around the source means a machine without nix-direnv still loads
`direnvrc`; only `use flake` is unavailable.

## `use_gh_account`

The direnv and gh binaries both come from [`flake.nix`](../flake.nix). direnv
was previously apt's 2.32.1 while nix-direnv — a direnv plugin — came from the
flake, so host and plugin sat under different managers. gh's tokens live in the
system keyring, so it is unaffected by where gh itself is installed.

Two GitHub accounts are logged in (`gh auth status`): `jakeryderv` (default,
personal) and `ah-jakev` (work). Tokens live in the system keyring, not in
`~/.config/gh/`. gh has no built-in per-directory switching - upstream keeps
context-based switching out of scope and documents `GH_TOKEN=$(gh auth token
--user X)` as the intended automation hook - so direnv fills the gap:

```bash
# ~/dev/arrow/gh/<repo>/.envrc
use_gh_account ah-jakev
```

The helper **fails closed**. If the keyring lookup fails - locked keyring, or
that account logged out - it exports an invalid placeholder token rather than
leaving `GH_TOKEN` empty. This matters because gh treats an empty `GH_TOKEN` as
unset and silently falls back to the default account, so a locked keyring would
otherwise mean work repos quietly operating as `jakeryderv`. With the
placeholder, gh reports an invalid token instead.

Scope note: this only affects gh's API calls. Git operations in those repos
authenticate over SSH via the `github.com-work` host alias in `~/.ssh/config`
(`~/.ssh/id_ed25519_work`), independent of gh.

## Consumers

`.envrc` files are per-repo and live in those repos, not here:

| Repo | Account |
| --- | --- |
| `~/dev/arrow/gh/winchsim` | `ah-jakev` |
| `~/dev/arrow/gh/winch-lab` | `ah-jakev` |

Editing a `.envrc` revokes direnv's approval - run `direnv allow` in that repo
afterward.

## Fresh machine

```bash
sudo apt install direnv
just apply direnv
```

Then, for gh multi-account use: `gh auth login` for each account (tokens go to
the keyring), confirm with `gh auth status`, and add `use_gh_account <user>` to
the relevant repo `.envrc` files.
