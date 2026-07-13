# _wallpapers

Wallpaper / terminal background images.

**Not a stow package.** The `_` prefix keeps this directory out of `dots`
package discovery. The files just live in the repo and are referenced by
absolute path.

## Who uses these

Configs point at these images directly by path:

- [`ghostty`](../ghostty/README.md) — `background-image = ~/.dots/_wallpapers/black_2560x1600.png`
- [`wezterm`](../wezterm/README.md) — `window_background_image = ~/.dots/_wallpapers/dark-space-blur-s5.jpg`

Because they're referenced by `~/.dots/_wallpapers/...`, the repo must live at
`~/.dots` for those backgrounds to resolve (or update the paths).

## Adding one

Drop the image in this directory, commit it, then point a config at
`~/.dots/_wallpapers/<file>`.
