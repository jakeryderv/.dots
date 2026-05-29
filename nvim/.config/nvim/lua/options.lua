vim.o.number = true
vim.o.relativenumber = true

-- Absolute numbers in insert mode, relative in normal
vim.api.nvim_create_autocmd('InsertEnter', {
  callback = function()
    vim.opt.relativenumber = false
  end,
})
vim.api.nvim_create_autocmd('InsertLeave', {
  callback = function()
    vim.opt.relativenumber = true
  end,
})

vim.o.mouse = 'a'
vim.o.showmode = false

vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

vim.o.breakindent = true
vim.o.undofile = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- 2-space indent for web filetypes (matches prettier's default)
vim.api.nvim_create_autocmd('FileType', {
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

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true

-- Transparent background
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    vim.cmd([[
      hi Normal guibg=NONE ctermbg=NONE
      hi NormalNC guibg=NONE ctermbg=NONE
    ]])
  end,
})
