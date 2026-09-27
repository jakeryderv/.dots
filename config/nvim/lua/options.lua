vim.o.number = true
vim.o.relativenumber = true

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
-- -1 makes softtabstop follow shiftwidth, so <Tab>/<BS> move by a whole indent
-- step instead of a single space (the default sts=0 with expandtab).
vim.o.softtabstop = -1
vim.o.expandtab = true

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true

-- No default border for floating windows that don't set their own (e.g. LSP
-- hover, signature help). Telescope and diagnostic floats set rounded borders
-- themselves, so they're unaffected.
vim.o.winborder = 'none'

-- Treesitter-based folding: folds follow code structure (functions, blocks…).
-- foldlevelstart = 99 means files open with everything UNfolded; you fold on demand.
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.o.foldlevelstart = 99

-- Compose files are plain 'yaml' by default; the compound filetype lets
-- docker_language_server attach while yaml tooling (yamlls, prettierd,
-- treesitter) still applies. Covers compose.yml, docker-compose.yml and
-- override files like compose.override.yaml / docker-compose.prod.yml.
vim.filetype.add({
  pattern = {
    ['.*/docker%-compose[%w.-]*%.ya?ml'] = 'yaml.docker-compose',
    ['.*/compose[%w.-]*%.ya?ml'] = 'yaml.docker-compose',
  },
})
