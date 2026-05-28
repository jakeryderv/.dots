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
        vim.b.miniindentscope_disable = true
      end,
    })
  end,
  opts = {
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
