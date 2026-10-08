-- Absolute line numbers + no whitespace listchars in insert mode; relative
-- numbers + listchars back in normal mode. Hiding listchars while typing keeps
-- the trailing-space '·' from flickering under the cursor mid-edit.
local numbers = vim.api.nvim_create_augroup('numbers', { clear = true })
vim.api.nvim_create_autocmd('InsertEnter', {
  group = numbers,
  callback = function()
    vim.opt.relativenumber = false
    vim.opt.list = false
  end,
})
vim.api.nvim_create_autocmd('InsertLeave', {
  group = numbers,
  callback = function()
    vim.opt.relativenumber = true
    vim.opt.list = true
  end,
})

-- 2-space indent for filetypes whose formatter emits 2 (prettier's default;
-- stylua for lua). Without lua here you'd type 4-wide and stylua would rewrite
-- the file to 2 on save. softtabstop is global (-1, follows shiftwidth), so it
-- doesn't need setting per filetype.
--
-- A project .editorconfig overrides all of this -- it is applied after FileType
-- and wins, which is the intended precedence.
-- The pattern list is grouped by language family, not one entry per line.
-- stylua: ignore
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('web-indent', { clear = true }),
  pattern = {
    'lua',
    'html', 'css', 'scss', 'sass', 'less',
    'javascript', 'javascriptreact', 'typescript', 'typescriptreact',
    'json', 'jsonc', 'yaml', 'markdown',
  },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
  end,
})

-- Transparent background + dim whitespace (re-applied on every colorscheme
-- change). carbonfox sets Whitespace fg == CursorLine bg (#353535), so on the
-- current line the trailing '·' collides with the cursorline background and
-- vanishes/looks solid under the block cursor. Retint listchars to bg4
-- (#535353): visible against both the normal (#161616) and cursorline
-- (#353535) backgrounds, so they stay uniformly dim everywhere.
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('transparent-bg', { clear = true }),
  callback = function()
    local c = require('colors')
    vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'NormalNC', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'Whitespace', { fg = c.bg4 })
    vim.api.nvim_set_hl(0, 'NonText', { fg = c.bg4 })
  end,
})

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Follow markdown links with <CR>: [[wiki]] links open <name>.md, [text](url)
-- links open URLs externally / local paths in nvim, GitHub-style: relative to
-- the file, or to the vault root (an Obsidian vault or .marksman.toml root,
-- else the git repo) with a leading '/'; #anchors use GitHub slugs.
-- Falls back to next line.
-- Links go to the language server (marksman) first, which resolves them
-- across the whole root, including [[wiki]] names and #headings. Anything it
-- can't resolve falls through to the path rules.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('markdown-links', { clear = true }),
  pattern = { 'markdown', 'quarto', 'rmd' },
  callback = function(args)
    vim.bo[args.buf].suffixesadd = '.md'

    -- Insert [name](/path.md) / [Heading](/path.md#anchor) via Telescope;
    -- in visual mode the selection becomes the link text.
    local links = require('markdown_links')
    vim.keymap.set({ 'n', 'x' }, '<leader>mf', links.pick_file, { buffer = args.buf, desc = 'Markdown: Link to file' })
    vim.keymap.set({ 'n', 'x' }, '<leader>mh', links.pick_heading, { buffer = args.buf, desc = 'Markdown: Link to heading' })

    -- Local link targets resolve relative to this file (not the cwd), or to
    -- the vault root (links.root) when they start with '/'. An #anchor jumps
    -- to the heading.
    local function open_relative(path, anchor)
      local root = path:match('^/') and links.root(args.buf)
      if root then
        path = root .. path
      elseif path ~= '' and not path:match('^/') then
        path = vim.fs.joinpath(vim.fs.dirname(vim.api.nvim_buf_get_name(args.buf)), path)
      end
      if path ~= '' then
        vim.cmd.edit(vim.fn.fnameescape(vim.fs.normalize(path)))
      end
      if anchor then
        for _, h in ipairs(links.headings(vim.api.nvim_buf_get_lines(0, 0, -1, false))) do
          if h.anchor == anchor:lower() then
            vim.api.nvim_win_set_cursor(0, { h.lnum, 0 })
            break
          end
        end
      end
    end

    local function lsp_or(fallback)
      local client = vim.lsp.get_clients({ bufnr = args.buf, method = 'textDocument/definition' })[1]
      if not client then
        return fallback()
      end
      local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
      client:request('textDocument/definition', params, function(err, result)
        local loc = result and (result.uri and result or result[1])
        if err or not loc then
          return fallback()
        end
        vim.lsp.util.show_document(loc, client.offset_encoding, { focus = true })
      end, args.buf)
    end

    vim.keymap.set('n', '<CR>', function()
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2] + 1

      for s, target, e in line:gmatch('()%[%[([^%]|]+)[^%]]*%]%]()') do
        if col >= s and col < e then
          lsp_or(function()
            local file = target:match('^([^#]+)') or target
            open_relative(file .. '.md')
          end)
          return
        end
      end

      for s, url, e in line:gmatch('()%[[^%]]+%]%(([^%)]+)%)()') do
        if col >= s and col < e then
          if url:match('^https?://') or url:match('^mailto:') then
            vim.ui.open(url)
            return
          end
          -- <...> wraps destinations that contain spaces.
          local file, anchor = url:gsub('^<(.*)>$', '%1'):match('^([^#]*)#?(.*)$')
          local function open_path()
            open_relative(file, anchor ~= '' and anchor or nil)
          end
          -- Note links are .md or extensionless; other files (images,
          -- scripts) are opened directly even inside a vault.
          if file:match('%.md$') or not file:match('%.%w+$') then
            lsp_or(open_path)
          else
            open_path()
          end
          return
        end
      end

      vim.cmd('normal! +')
    end, { buffer = args.buf, desc = 'Markdown: Follow link' })
  end,
})
