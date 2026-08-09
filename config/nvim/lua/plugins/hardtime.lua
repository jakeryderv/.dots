return {
  -- Breaks bad editing habits by nudging you toward efficient motions.
  -- Starts disabled -- opt in per session with `:Hardtime enable`.
  -- Toggle with `:Hardtime toggle`, report with `:Hardtime report`.
  'm4xshen/hardtime.nvim',
  -- Starts disabled and is only ever invoked via :Hardtime, so load on demand.
  cmd = 'Hardtime',
  dependencies = { 'MunifTanjim/nui.nvim' },
  opts = { enabled = false },
}
