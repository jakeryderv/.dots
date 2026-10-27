return {
  'MeanderingProgrammer/render-markdown.nvim',
  -- render-markdown attaches to the lazy.nvim `ft` list itself.
  ft = { 'markdown', 'quarto' },
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
  keys = {
    {
      '<leader>mr',
      function()
        require('render-markdown').toggle()
      end,
      ft = { 'markdown', 'quarto' },
      desc = 'Markdown: Toggle render',
    },
  },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {},
}
