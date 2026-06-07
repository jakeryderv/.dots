return {
  -- Breaks bad editing habits by nudging you toward efficient motions.
  -- Starts disabled -- opt in per session with `:Hardtime enable`.
  -- Toggle with `:Hardtime toggle`, report with `:Hardtime report`.
  'm4xshen/hardtime.nvim',
  lazy = false,
  dependencies = { 'MunifTanjim/nui.nvim' },
  opts = { enabled = false },
}
