# thunar

[Thunar](https://docs.xfce.org/xfce/thunar/start) file manager preferences and
a Thunar-only Carbonfox GTK theme. Stowed into `~/.config/` and `~/.local/`.

See the root [README](../README.md) for shared Stow mechanics.

## Files

| File | Role |
| --- | --- |
| `.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml` | View, sorting, tabs, thumbnails, chrome, and safety preferences. |
| `.config/Thunar/uca.xml` | Custom context-menu actions, including opening Ghostty in the current directory. |
| `.local/share/themes/Carbonfox-Thunar/` | GTK 3 theme scoped to the Thunar launcher. |
| `.local/bin/thunar-carbonfox` | Launches Thunar with the scoped GTK theme. |
| `.local/share/applications/thunar.desktop` | User-level launcher override that uses the themed wrapper. |

## Activate

Close every Thunar window before stowing, then run:

```bash
cd ~/.dots && dots stow --apply thunar
```

Log out and back in, or reboot, after the first activation so COSMIC refreshes
the launcher entry and the first Thunar process inherits the scoped theme.

## Notable choices

- Details view with Name, Size, Modified, and Permissions columns.
- Hidden files shown; natural case-insensitive sorting with folders first.
- Local thumbnails, compact icons, and a shortcuts sidebar.
- Breadcrumb navigation with a minimal toolbar, hidden menubar, and hidden
  statusbar.
- Externally opened folders reuse the current window as new tabs.
- `0xProto Nerd Font Mono` at 12pt and the Carbonfox palette.
- Double-click activation, confirmation before closing multiple tabs, and
  shell scripts opened instead of executed by default.

## Theme scope

COSMIC generates and owns the global `~/.config/gtk-3.0/gtk.css` symlink. This
package deliberately leaves it alone. The desktop entry starts Thunar with
`GTK_THEME=Carbonfox-Thunar`, so other GTK applications keep the COSMIC theme.

## Dependencies

- `thunar` and `xfconf`
- `ghostty` for the **Open Ghostty Here** custom action
- `0xProto Nerd Font Mono` from [`fonts`](../fonts/README.md)
