# nix/

The pieces [`flake.nix`](../flake.nix) imports. The flake itself stays at the
root because Nix requires it there, and stays thin: inputs and wiring.

| File | Purpose |
| --- | --- |
| `tools.nix` | The toolchain as a function of `pkgs`, with each entry's reason inline. Exposed as `lib.tools`. |
| `dots.nix` | The `dots` command as a package: a wrapper that execs the live `dots.py` with a pinned python. |

How the flake is used, and why each tool is or is not in it, is in
[`docs/nix.md`](../docs/nix.md).
