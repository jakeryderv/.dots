return {
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
      -- Schema catalog library for jsonls/yamlls; required from before_init.
      { 'b0o/SchemaStore.nvim', version = false },
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
          end

          -- Follow Neovim's built-in gr* LSP keys (grn rename, grx codelens are
          -- left as defaults); only swap the list-producing ones to Telescope
          -- pickers instead of the quickfix list. gra is tiny-code-action's
          -- previewing picker (tiny-code-action.lua).
          map('gd', require('telescope.builtin').lsp_definitions, 'LSP: Goto definition')
          map('gD', vim.lsp.buf.declaration, 'LSP: Goto declaration')
          map('grr', require('telescope.builtin').lsp_references, 'LSP: Goto references')
          map('gri', require('telescope.builtin').lsp_implementations, 'LSP: Goto implementation')
          map('grt', require('telescope.builtin').lsp_type_definitions, 'LSP: Goto type definition')
          map('gO', require('telescope.builtin').lsp_document_symbols, 'LSP: Document symbols')
          map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'LSP: Workspace symbols')
          -- The built-in code action menu without a preview: a fallback for gra.
          -- Shadows Vim's virtual-replace `gr{char}` for 'A' only, which
          -- differs from `rA` just on Tabs.
          map('grA', vim.lsp.buf.code_action, 'LSP: Code action (no preview)', { 'n', 'x' })

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = 'lsp-highlight', buffer = event2.buf })
              end,
            })
          end

          -- ty owns Python hover; ruff's only explains rule codes and would
          -- compete with it for the K float.
          if client and client.name == 'ruff' then
            client.server_capabilities.hoverProvider = false
          end

          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            -- Rust leans on inference, so its type/parameter hints start on.
            -- (rustaceanvim names the client 'rust-analyzer', not lspconfig's
            -- 'rust_analyzer'.)
            if client.name == 'rust-analyzer' then
              vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
            end
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
            end, 'Toggle: Inlay hints')
          end

          -- Daily notes in natural language: :Daily, :Daily yesterday,
          -- :Daily next monday, :Daily -3. lspconfig's own on_attach also adds
          -- :LspToday / :LspYesterday / :LspTomorrow.
          if client and client.name == 'markdown_oxide' then
            vim.api.nvim_buf_create_user_command(event.buf, 'Daily', function(args)
              local when = args.args ~= '' and args.args or 'today'
              client:exec_cmd({ title = 'Daily note', command = 'jump', arguments = { when } }, { bufnr = event.buf })
            end, { nargs = '*', desc = 'Open daily note' })
            map('<leader>md', '<cmd>Daily<cr>', "Markdown: Today's daily note")
          end
        end,
      })

      vim.diagnostic.config({
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
        },
      })

      -- Completion capabilities from blink, applied to every server via the
      -- '*' default config (replaces the old per-handler capabilities merge).
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      vim.lsp.config('*', { capabilities = capabilities })

      -- Per-server settings. An empty table = nvim-lspconfig's base config
      -- (shipped in its lsp/ dir) plus the capabilities above. We layer our
      -- settings on top with vim.lsp.config(), then enable explicitly below.
      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
            },
          },
        },
        bashls = {},

        -- Web: HTML/CSS/JS/TS. vtsls handles JS embedded in HTML <script> tags.
        html = {},
        cssls = {},
        emmet_language_server = {},
        vtsls = {},

        -- C/C++. clangd runs clang-tidy itself (a project .clang-tidy picks the
        -- checks); real projects need a compile_commands.json.
        clangd = {
          cmd = { 'clangd', '--clang-tidy' },
        },

        -- Dockerfile + Compose (Compose files are detected in options.lua).
        docker_language_server = {},

        -- Data formats. SchemaStore supplies the JSON/YAML schema catalog
        -- (package.json, tsconfig, GitHub workflows, compose, ...).
        jsonls = {
          before_init = function(_, config)
            config.settings.json.schemas = require('schemastore').json.schemas()
          end,
          settings = { json = { validate = { enable = true } } },
        },
        yamlls = {
          before_init = function(_, config)
            config.settings.yaml.schemas = require('schemastore').yaml.schemas()
          end,
          settings = {
            yaml = {
              -- Disable yamlls's built-in catalog download; SchemaStore.nvim
              -- provides the same catalog.
              schemaStore = { enable = false, url = '' },
            },
          },
        },
        -- TOML: also the formatter, via conform's lsp_format fallback.
        tombi = {},

        -- Markdown notes: Obsidian-style [[links]], backlinks (grr), tags and
        -- daily notes. The vault is the nearest .git / .obsidian / .moxide.toml
        -- root; settings are in ~/.config/moxide/settings.toml (config/moxide).
        markdown_oxide = {
          -- lspconfig's flat { '.git', '.obsidian', '.moxide.toml' } searches
          -- for .git first, so a vault inside a git repo (or under a stray
          -- ~/.git) took the outer root. Explicit vault markers win here.
          root_markers = require('markdown_links').root_markers,
          -- Required by markdown-oxide so it sees files created outside the
          -- buffer, e.g. by its "create unresolved file" code action.
          capabilities = {
            workspace = { didChangeWatchedFiles = { dynamicRegistration = true } },
          },
        },
      }

      -- Enabled like the servers above but installed outside Mason.
      -- ty comes from uv (`uv tool install ty`); so does ruff, whose server
      -- adds lint diagnostics and quick fixes (formatting stays in conform).
      -- rust-analyzer is not listed: rustaceanvim.lua starts it.
      local external_servers = {
        ty = {},
        ruff = {},
      }

      for name, cfg in pairs(vim.tbl_extend('error', servers, external_servers)) do
        vim.lsp.config(name, cfg)
      end

      -- Install the servers (mason-lspconfig translates lspconfig -> mason
      -- package names).
      -- automatic_enable = false so ONLY the servers we vim.lsp.enable() below
      -- start -- this stops mason-lspconfig 2.x from auto-enabling extras like
      -- stylua's LSP mode.
      -- Mason installs language servers and nothing else. Global formatters,
      -- linters and the Tree-sitter CLI follow docs/software.md.
      require('mason-lspconfig').setup({
        ensure_installed = vim.tbl_keys(servers),
        automatic_enable = false,
      })

      -- Start the servers (on matching filetypes). This replaces the removed
      -- mason-lspconfig `handlers` mechanism.
      vim.lsp.enable(vim.tbl_keys(servers))
      vim.lsp.enable(vim.tbl_keys(external_servers))
    end,
  },
}
