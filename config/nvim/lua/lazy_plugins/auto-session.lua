return {
  'rmagatti/auto-session',
  -- Manual only: never saves/restores automatically. Driven entirely by the
  -- <leader>S keymaps / :AutoSession commands below.
  cmd = 'AutoSession',
  keys = {
    { '<leader>Ss', '<cmd>AutoSession search<cr>', desc = 'Session: Search' },
    { '<leader>Sw', '<cmd>AutoSession save<cr>', desc = 'Session: Save' },
    { '<leader>Sr', '<cmd>AutoSession restore<cr>', desc = 'Session: Restore (cwd)' },
    { '<leader>Sd', '<cmd>AutoSession deletePicker<cr>', desc = 'Session: Delete' },
  },
  opts = {
    auto_save = false,
    auto_restore = false,
  },
}
