return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  init = function()
    vim.api.nvim_create_autocmd({ 'FileType', 'BufWinEnter', 'WinEnter' }, {
      pattern = 'snacks_dashboard',
      callback = function()
        vim.opt_local.cursorline = false
        vim.opt_local.cursorcolumn = false
        vim.opt_local.signcolumn = 'no'
        vim.opt_local.foldcolumn = '0'
        vim.opt_local.list = false
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.colorcolumn = ''
      end,
    })
  end,
  opts = {
    indent = {
      enabled = true,
      -- Faint dotted guides on every indent level (distinct from mini.indentscope's solid │)
      indent = {
        char = '┊',
        only_scope = false,
        only_current = false,
      },
      -- Current-scope highlighting is handled by mini.indentscope; don't double-draw it here
      scope = { enabled = false },
      animate = { enabled = false },
      -- Normal file buffers only; skip special UIs and noisy filetypes
      filter = function(buf)
        local ft = vim.bo[buf].filetype
        local skip = {
          help = true, dashboard = true, snacks_dashboard = true,
          ['neo-tree'] = true, Trouble = true, lazy = true, mason = true,
          notify = true, toggleterm = true, markdown = true, text = true,
        }
        return vim.g.snacks_indent ~= false
          and vim.b[buf].snacks_indent ~= false
          and vim.bo[buf].buftype == ''
          and not skip[ft]
      end,
    },
    styles = {
      dashboard = {
        wo = {
          cursorline = false,
          cursorcolumn = false,
          signcolumn = 'no',
          foldcolumn = '0',
          list = false,
          number = false,
          relativenumber = false,
          spell = false,
        },
      },
    },
    dashboard = {
      enabled = true,
      preset = {
        header = [[]],
        keys = {
          { icon = ' ', key = 'f', desc = 'Find File', action = ":lua Snacks.dashboard.pick('files')" },
          { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
          { icon = ' ', key = 'g', desc = 'Find Text', action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = ' ', key = 'r', desc = 'Recent Files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })" },
          { icon = ' ', key = 's', desc = 'Restore Session', section = 'session' },
          { icon = '󰒲 ', key = 'L', desc = 'Lazy', action = ':Lazy', enabled = package.loaded.lazy ~= nil },
          { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
        },
      },
      sections = {
        { section = 'header' },
        { section = 'keys', gap = 1, padding = 1 },
        { section = 'recent_files', icon = ' ', title = 'Recent Files', indent = 2, padding = 1 },
        { section = 'projects', icon = ' ', title = 'Projects', indent = 2, padding = 1 },
        { section = 'startup' },
      },
    },
  },
}
