-- Absolute line numbers in insert mode, relative in normal mode
local numbers = vim.api.nvim_create_augroup('numbers', { clear = true })
vim.api.nvim_create_autocmd('InsertEnter', {
  group = numbers,
  callback = function()
    vim.opt.relativenumber = false
  end,
})
vim.api.nvim_create_autocmd('InsertLeave', {
  group = numbers,
  callback = function()
    vim.opt.relativenumber = true
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

-- Transparent background (re-applied on every colorscheme change)
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('transparent-bg', { clear = true }),
  callback = function()
    vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'NormalNC', { bg = 'none' })
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
