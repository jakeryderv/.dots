# moxide

Global settings for [markdown-oxide](https://github.com/Feel-ix-343/markdown-oxide),
the Markdown language server Neovim uses for Obsidian-style notes. Mason
installs the server; this package only ships its configuration:

```bash
dots plan moxide
dots apply moxide
```

`config/moxide/settings.toml` deploys to `~/.config/moxide/settings.toml` in
`link` mode. The full option list is upstream's
[Configuration](https://github.com/Feel-ix-343/markdown-oxide/blob/main/docs/Markdown%20Oxide%20Docs/Configuration.md).

## Vault layout

A vault is the nearest directory containing `.obsidian` or `.moxide.toml`,
otherwise the enclosing git repo, so every git repo is its own vault. (The
explicit markers win over `.git`, so an Obsidian vault inside a repo is its
own vault; `lua/markdown_links.lua` holds the marker list, shared by
markdown-oxide, the link pickers, `<CR>` and image paste.) A git repo's root
files, `docs/` and `notes/` all resolve against each other:

```text
project/
├── README.md
├── docs/
└── notes/
    ├── daily/      # :Daily, :LspToday, Space m d
    └── assets/     # pasted images (img-clip, Space m i)
```

- **New notes**: the "create file" code action on an unresolved link
  (`gra`) writes to `notes/`.
- **Daily notes**: `%Y-%m-%d.md` in `notes/daily/`, created on first open.
- **Excluded**: `node_modules`, `target`, `.venv`, `venv` and `dist`, matched by
  directory name at any depth.

A project can override any setting with its own `.moxide.toml`; a
`.moxide.toml` in a subdirectory also makes that subdirectory its own vault.

## Obsidian vaults

markdown-oxide reads a vault's `.obsidian/daily-notes.json` (folder, format)
and `.obsidian/app.json` (new-file folder), but only as fallbacks: the global
`settings.toml` above outranks them. A vault whose Obsidian settings differ
from the global `notes/` layout needs a `.moxide.toml` at its root mirroring
them. `~/obsidian/main` has one:

```toml
daily_notes_folder = "daily"
new_file_folder_path = "notes"
```

Image paste (**Space m i**) uses the vault's `attachmentFolderPath` from
`.obsidian/app.json` (`attachments/` there) instead of `notes/assets/`. Hidden
folders such as Obsidian's `.trash` are never indexed.

## Link resolution

markdown-oxide resolves `[[wiki]]` links by note name anywhere in the vault,
and standard Markdown links relative to the **vault root**, so a link to
`docs/guide.md` works the same from any note. `../` links are not resolved by
the server; Neovim's `<CR>` falls back to resolving them relative to the file
(see [nvim.md](nvim.md#notes-markdown-oxide)).
