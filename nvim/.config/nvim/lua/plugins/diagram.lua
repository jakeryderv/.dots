return {
  '3rd/diagram.nvim',
  dependencies = { '3rd/image.nvim' },
  ft = { 'markdown', 'norg' },
  opts = function()
    return {
      integrations = {
        require('diagram.integrations.markdown'),
      },
      renderer_options = {
        mermaid = {
          background = 'transparent',
          theme = 'forest',
          scale = 2,
        },
        d2 = {
          theme_id = 1,
        },
      },
    }
  end,
}
