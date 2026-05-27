return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = 'VeryLazy',
  opts = {
    options = {
      mode = 'buffers',
      separator_style = 'thin',
      always_show_bufferline = true,
      show_buffer_close_icons = false,
      show_close_icon = false,
      diagnostics = 'nvim_lsp',
      numbers = function(opts)
        return string.format('[%s]', opts.ordinal)
      end,
    },
    highlights = {
      fill = { bg = '#161616' },
      background = { bg = '#161616', fg = '#6e6f70' },
      buffer_selected = { bg = '#2a2a2a', fg = '#f2f4f8', bold = true },
      buffer_visible = { bg = '#161616', fg = '#6e6f70' },
      separator = { fg = '#161616', bg = '#161616' },
      separator_selected = { fg = '#161616', bg = '#2a2a2a' },
      separator_visible = { fg = '#161616', bg = '#161616' },
      numbers = { bg = '#161616', fg = '#535353' },
      numbers_selected = { bg = '#2a2a2a', fg = '#535353', bold = true },
      numbers_visible = { bg = '#161616', fg = '#535353' },
    },
  },
}
