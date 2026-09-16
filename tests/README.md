# tests/

Behaviour tests for [`dots.py`](../dots.py), run by `dots check`:

```bash
python3 -m unittest discover -s tests
```

They build a throwaway fixture repo with its own `dots.toml` and git history,
then drive the real CLI against a scratch `$HOME`: both modes, `links`
fan-out, untracked-file exclusion, idempotent apply, package filtering,
conflict refusal, stale-link repointing, selective unlink, every `validate`
rule, and the gate itself on the fixture.

`test_herdr_navigation.py` additionally exercises the Neovim Herdr integration
loader with a mocked CLI and a temporary plugin checkout: ordinary/tmux startup,
installed and disabled bridges, missing files, malformed output, and binary
selection. It never contacts a live Herdr server and skips when Neovim is not
installed.
