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

-- 2-space indent for web filetypes (matches prettier's default)
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('web-indent', { clear = true }),
  pattern = {
    'html', 'css', 'scss', 'sass', 'less',
    'javascript', 'javascriptreact', 'typescript', 'typescriptreact',
    'json', 'jsonc', 'yaml', 'markdown',
  },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
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
-- links open URLs externally / local paths in nvim. Falls back to next line.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('markdown-links', { clear = true }),
  pattern = { 'markdown', 'quarto', 'rmd' },
  callback = function(args)
    vim.bo[args.buf].suffixesadd = '.md'

    vim.keymap.set('n', '<CR>', function()
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2] + 1

      for s, target, e in line:gmatch('()%[%[([^%]|]+)[^%]]*%]%]()') do
        if col >= s and col < e then
          local file = target:match('^([^#]+)') or target
          vim.cmd.edit(vim.fn.fnameescape(file .. '.md'))
          return
        end
      end

      for s, url, e in line:gmatch('()%[[^%]]+%]%(([^%)]+)%)()') do
        if col >= s and col < e then
          if url:match('^https?://') or url:match('^mailto:') then
            vim.ui.open(url)
          else
            local file = url:match('^([^#]+)') or url
            vim.cmd.edit(vim.fn.fnameescape(file))
          end
          return
        end
      end

      vim.cmd('normal! +')
    end, { buffer = args.buf, desc = 'Follow markdown link' })
  end,
})
