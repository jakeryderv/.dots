# leaf

[Leaf](https://github.com/RivoLink/leaf) previews Markdown in the terminal.
Install the CLI using the [software inventory](software.md#everyday-cli-tools),
then deploy its configuration:

```bash
dots plan leaf
dots apply leaf
```

`config/leaf/config.toml` deploys to `~/.config/leaf/config.toml` in `tree`
mode. The directory remains local so optional `history.toml` state stays out
of the repository. History recording remains disabled by Leaf's default.

The configuration enables watch mode and sets `Ctrl+E` to open Neovim at the
visible source line. Leaf reloads when the editor returns. Override the editor
for a session with `leaf --editor 'vim +{$line}' README.md`.

## Colors

`carbonfox.toml` supplies the same charcoal backgrounds and blue, purple,
teal, and pink accents as the repo's Neovim/Vim and terminal configurations.
It deploys beside `config.toml`; the theme path is relative to that directory,
so it works independently of the current working directory.

All exposed UI and Markdown colors are overridden. Fenced code syntax uses
Leaf's bundled `base16-ocean.dark` theme: Leaf selects syntax themes by name
from its bundled Syntect theme set and cannot import the Carbonfox `.tmTheme`
used by bat. Code token colors therefore remain an approximation.
See upstream's [theme resolution](https://github.com/RivoLink/leaf/blob/main/src/theme/resolution.rs).

Restart Leaf after changing the theme; watch mode reloads document content.

## Editor preview

In a Markdown buffer in either Vim or Neovim, use **Space m l** or
`:LeafPreview` to open the saved file in a new terminal split on the right.
Save with `:w` to refresh it; unsaved buffer edits are not previewed. The
command requires an existing file and does not save automatically. File paths
are passed as arguments, including paths containing spaces or shell characters.

- **Neovim:** press `Ctrl+\`, then `Ctrl+n` to leave terminal input mode,
  then `Ctrl+w h` to return to the editing split. The existing double-Escape
  mapping also leaves terminal input mode.
- **Vim:** press `Ctrl+w h` to return to the editing split. Requires `+terminal`.
- In Leaf, `q` exits the preview process; close its remaining split with `:q`.
  Each invocation opens a new split. Edit in the original buffer when using
  this workflow; Leaf's `Ctrl+E` opens a separate editor process.

Neovim's **Space m p** continues to toggle the Firefox preview. No additional
editor plugin is needed for Leaf. Restart an existing editor to load the mappings.

For a separate terminal or tmux pane, run `leaf -w README.md`.
See upstream's [configuration reference](https://github.com/RivoLink/leaf/blob/main/config.toml)
for optional themes, width limits, and file history.
