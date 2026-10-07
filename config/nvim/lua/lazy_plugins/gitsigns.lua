return {
  'lewis6991/gitsigns.nvim',
  opts = {
    signs = {
      add = { text = '+' },
      change = { text = '~' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
    },
    on_attach = function(bufnr)
      local gitsigns = require('gitsigns')

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal({ ']c', bang = true })
        else
          gitsigns.nav_hunk('next')
        end
      end, { desc = 'Git: Next hunk' })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal({ '[c', bang = true })
        else
          gitsigns.nav_hunk('prev')
        end
      end, { desc = 'Git: Prev hunk' })

      -- Actions
      -- visual mode
      map('v', '<leader>gs', function()
        gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      end, { desc = 'Git: Stage hunk' })
      map('v', '<leader>gr', function()
        gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      end, { desc = 'Git: Reset hunk' })
      -- normal mode (stage_hunk toggles: on an already-staged hunk it unstages)
      map('n', '<leader>gs', gitsigns.stage_hunk, { desc = 'Git: Stage/unstage hunk' })
      map('n', '<leader>gr', gitsigns.reset_hunk, { desc = 'Git: Reset hunk' })
      map('n', '<leader>gS', gitsigns.stage_buffer, { desc = 'Git: Stage buffer' })
      map('n', '<leader>gR', gitsigns.reset_buffer, { desc = 'Git: Reset buffer' })
      map('n', '<leader>gp', gitsigns.preview_hunk, { desc = 'Git: Preview hunk' })
      map('n', '<leader>gb', gitsigns.blame_line, { desc = 'Git: Blame line' })
      map('n', '<leader>gd', gitsigns.diffthis, { desc = 'Git: Diff against index' })
      map('n', '<leader>gD', function()
        gitsigns.diffthis('@')
      end, { desc = 'Git: Diff against last commit' })
      -- Toggles
      map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = 'Toggle: Git line blame' })
      map('n', '<leader>tD', gitsigns.preview_hunk_inline, { desc = 'Toggle: Git deleted lines' })
    end,
  },
}
