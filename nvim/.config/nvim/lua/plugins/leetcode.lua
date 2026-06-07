return {
  'kawre/leetcode.nvim',
  -- html parser is installed by the treesitter config (main branch), so the
  -- old `build = ':TSUpdate html'` (master-only syntax) is no longer needed.
  dependencies = {
    -- include a picker of your choice, see picker section for more details
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
  },
  opts = {
    lang = 'python3',
  },
}
