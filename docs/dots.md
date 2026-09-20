# dots

The repository's deployment and validation CLI. Requires Python 3.11 or newer
with its standard library; Pop!_OS 24.04 supplies Python 3.12.

`dots.toml` links the executable [`dots.py`](../dots.py) to `~/.local/bin/dots`.
The script resolves its own symlink to find the checkout, so it works from any
directory and edits take effect immediately. `--repo` overrides `DOTS_REPO`,
which overrides the script's directory. Python comes from `python3` on PATH.

## Activate

```bash
cd ~/.dots
python3 dots.py plan dots
python3 dots.py apply dots
~/.local/bin/dots status
```

The shared shell configuration adds `~/.local/bin` to PATH. See the root
[README](../README.md#the-dots-tool) for commands and deployment rules.
