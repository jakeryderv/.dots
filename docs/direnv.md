# direnv

Global [direnv](https://direnv.net/) extensions - shared helper functions for
per-directory environments. direnv itself is hooked into bash from
[`config/bash/bashrc`](bash.md) (`eval "$(direnv hook bash)"`), not from
this package.

## Tracked

| File | Purpose |
| --- | --- |
| `.config/direnv/direnvrc` | `use_gh_account` - pin the gh CLI to a specific GitHub account per directory tree |

`direnvrc` is sourced before every `.envrc`, so its functions need no
`source_env`. direnv watches the file: editing it invalidates cached
environments, and the next `cd` into a direnv directory re-evaluates.

## Nix integration retired

The global nix-direnv source hook has been removed. The work projects found
using direnv rely on `use_gh_account`, not Nix. Node projects use nvm and
`.nvmrc`; Python projects use uv. Upstream plugin checkouts can still contain
Nix development files, but loading those plugins does not evaluate their
`.envrc` or flakes.

## `use_gh_account`

direnv uses an [official release binary](software.md#editor-and-shell-tools).
GitHub CLI uses its [official apt repository](software.md#everyday-cli-tools).
Its existing system-keyring credentials are independent of the binary's
installation source.

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
| `~/dev/arrow/gh/winch-cad` | `ah-jakev` |
| `~/dev/arrow/gh/winch-lab` | `ah-jakev` |

Editing a `.envrc` revokes direnv's approval - run `direnv allow` in that repo
afterward.

## Fresh machine

Install direnv using the [software inventory](software.md#editor-and-shell-tools),
then deploy its configuration:

```bash
dots apply direnv
```

Then, for gh multi-account use: `gh auth login` for each account (tokens go to
the keyring), confirm with `gh auth status`, and add `use_gh_account <user>` to
the relevant repo `.envrc` files.
