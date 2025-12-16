return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup({
      open_mapping = [[<c-\>]],
      direction = 'float', -- float | horizontal | vertical | tab
      shade_terminals = true,
      start_in_insert = true,
      persist_size = true,
    })
  end,
}
