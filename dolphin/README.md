# dolphin

[Dolphin](https://apps.kde.org/dolphin/) file manager preferences. Stowed to
`~/.config/dolphinrc` and `~/.local/share/dolphin/`.

See the root [README](../README.md) for shared stow mechanics.

## Files

| File | Role |
|------|------|
| `.config/dolphinrc` | Behavior, view-mode typography and sizing, content formatting, context menu, and chrome preferences. |
| `.local/share/dolphin/view_properties/global/.directory` | Default folder view, columns, sorting, previews, and hidden-file visibility shared across locations. |

Window geometry, restored tabs, usage counters, KDE-wide settings, and Places
bookmarks are intentionally not tracked because they are volatile or
machine-specific.

## Activate

Close Dolphin before the first stow so it cannot rewrite the files while they
are being linked, then run:

```bash
cd ~/.dots && dots stow --apply dolphin
```

Dolphin writes generated timestamps to both tracked files when relevant
preferences change, so those timestamp-only diffs are expected.

## Notable choices

- **Details view everywhere** with Name, Size, Modified, and Permissions columns;
  natural name sorting; directories first; dotfiles last; and previews enabled.
- **Developer-friendly visibility** — hidden files are shown, full paths appear
  in both the breadcrumb bar and title, archives can be browsed as folders, and
  the context menu includes Copy/Move To and Open Terminal actions.
- **Font** — `0xProto Nerd Font Mono` at 12pt in Icons, Compact, and Details
  views (ships in [`fonts`](../fonts/README.md)).
- **Dense, quiet UI** — 22px Details/Compact icons, reduced Details row padding,
  locked panels, no hover tooltips or selection markers, and no zoom slider.
- **Predictable sessions** — new windows start clean instead of restoring old
  tabs; externally opened folders become tabs; new tabs append at the end; and
  Tab switches between split panes.
- **Technical metadata** — relative dates and combined symbolic/numeric
  permissions; directory rows show item counts instead of recursively scanning
  their full size.

## Theme scope

Dolphin does not own its color palette in `dolphinrc`. Under COSMIC it inherits
the Qt 5 palette selected by `~/.config/qt5ct/qt5ct.conf`, which is currently
COSMIC Dark. A Carbonfox Qt palette should therefore be managed as a separate
Qt/COSMIC package because selecting it would affect other Qt 5 applications,
not only Dolphin.
