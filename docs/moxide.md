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

A vault is the nearest directory containing `.git`, `.obsidian` or
`.moxide.toml`, so every git repo is its own vault. Its root files,
`docs/` and `notes/` all resolve against each other:

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

The main Obsidian vault is kept separate and is edited in the Obsidian app.
A project can override any setting with its own `.moxide.toml`; a
`.moxide.toml` in a subdirectory also makes that subdirectory its own vault.

## Link resolution

markdown-oxide resolves `[[wiki]]` links by note name anywhere in the vault,
and standard Markdown links relative to the **vault root**, so a link to
`docs/guide.md` works the same from any note. `../` links are not resolved by
the server; Neovim's `<CR>` falls back to resolving them relative to the file
(see [nvim.md](nvim.md#notes-markdown-oxide)).
