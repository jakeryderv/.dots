return {
  'echasnovski/mini.nvim',
  config = function()
    require('mini.ai').setup { n_lines = 500 }
    require('mini.surround').setup()
    require('mini.indentscope').setup {
      symbol = '│',
      options = { try_as_border = true },
    }

    -- mini.statusline removed in favor of lualine.nvim
  end,
}
