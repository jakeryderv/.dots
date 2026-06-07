return {
  'rmagatti/auto-session',
  -- Manual only: never saves/restores automatically. Driven entirely by the
  -- <leader>S keymaps / :AutoSession commands below.
  cmd = 'AutoSession',
  keys = {
    { '<leader>Ss', '<cmd>AutoSession search<cr>', desc = '[S]ession [s]earch/pick' },
    { '<leader>Sw', '<cmd>AutoSession save<cr>', desc = '[S]ession [w]rite/save' },
    { '<leader>Sr', '<cmd>AutoSession restore<cr>', desc = '[S]ession [r]estore (cwd)' },
    { '<leader>Sd', '<cmd>AutoSession deletePicker<cr>', desc = '[S]ession [d]elete (pick)' },
  },
  opts = {
    auto_save = false,
    auto_restore = false,
  },
}
