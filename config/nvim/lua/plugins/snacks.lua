return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    -- Top-right notification toasts (replaces noice's toasts; only hooks vim.notify, never the cmdline)
    notifier = {
      enabled = true,
      timeout = 3000, -- ms before a notification fades
    },
  },
}
