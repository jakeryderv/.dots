return {
  'MeanderingProgrammer/render-markdown.nvim',
  -- render-markdown attaches to the lazy.nvim `ft` list itself.
  ft = { 'markdown' },
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
  keys = {
    {
      '<leader>mr',
      function()
        require('render-markdown').toggle()
      end,
      ft = 'markdown',
      desc = '[M]arkdown [R]ender toggle',
    },
  },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {},
}
