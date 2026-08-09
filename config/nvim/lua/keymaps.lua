vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Toggle the built-in (opt-in) undotree plugin; packadd is idempotent and
-- :Undotree closes the window if it's already open.
vim.keymap.set('n', '<leader>u', function()
  vim.cmd.packadd('nvim.undotree')
  vim.cmd.Undotree()
end, { desc = 'Toggle [U]ndotree' })

-- Zoom/maximize the current window (toggle); restores the prior layout.
-- Uses snacks.zen.zoom() -- no extra plugin (snacks is already loaded).
vim.keymap.set('n', '<leader>z', function()
  Snacks.zen.zoom()
end, { desc = '[Z]oom/maximize window' })
