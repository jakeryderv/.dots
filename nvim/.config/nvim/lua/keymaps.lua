vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Highlight when yanking text
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
