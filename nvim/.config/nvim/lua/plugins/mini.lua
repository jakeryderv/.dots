return {
  'echasnovski/mini.nvim',
  config = function()
    require('mini.ai').setup { n_lines = 500 }
    require('mini.surround').setup()

    -- mini.statusline removed in favor of lualine.nvim
    -- mini.indentscope removed in favor of snacks.indent's scope renderer
  end,
}
