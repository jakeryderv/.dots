return {
  'christoomey/vim-tmux-navigator',
  -- Load before any navigation key is pressed so lazy key handlers cannot
  -- replace the Herdr bridge's mappings later. Outside Herdr, keep tmux keys.
  lazy = false,
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  cmd = {
    'TmuxNavigateLeft',
    'TmuxNavigateDown',
    'TmuxNavigateUp',
    'TmuxNavigateRight',
    'TmuxNavigatePrevious',
  },
  keys = {
    { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
    { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
    { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
    { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
    { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
  },
  config = function()
    if not vim.env.HERDR_PANE_ID or vim.env.HERDR_PANE_ID == '' then
      return
    end

    -- Use Herdr's installed, pinned checkout instead of a second lazy.nvim
    -- clone or a hard-coded managed directory name. See docs/herdr.md.
    local herdr = vim.env.HERDR_BIN_PATH
    if not herdr or herdr == '' then
      herdr = 'herdr'
    end
    local result = vim.system({ herdr, 'plugin', 'list', '--plugin', 'vim-herdr-navigation', '--json' }, { text = true }):wait(2000)
    local ok, response = pcall(vim.json.decode, result.stdout or '')
    local plugins = ok and type(response) == 'table' and response.result and response.result.plugins
    local plugin = plugins and plugins[1]
    if result.code == 0 and plugin and plugin.enabled and plugin.plugin_root then
      local editor = plugin.plugin_root .. '/editor/nvim.lua'
      if vim.fn.filereadable(editor) == 1 then
        dofile(editor)
        return
      end
    end

    vim.schedule(function()
      vim.notify('Herdr Vim bridge unavailable; install/enable vim-herdr-navigation (docs/herdr.md)', vim.log.levels.WARN)
    end)
  end,
}
