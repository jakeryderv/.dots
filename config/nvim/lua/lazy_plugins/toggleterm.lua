return {
  'akinsho/toggleterm.nvim',
  version = '*',
  -- open_mapping below works in normal + insert mode; lazy-load on it.
  keys = { { [[<M-`>]], mode = { 'n', 'i' } } },
  cmd = { 'ToggleTerm', 'TermExec' },
  config = function()
    require('toggleterm').setup({
      open_mapping = [[<M-`>]],
      direction = 'float',
      shade_terminals = true,
      start_in_insert = true,
      persist_size = true,
    })
  end,
}
