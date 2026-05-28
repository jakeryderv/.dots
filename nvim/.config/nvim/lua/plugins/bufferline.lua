return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = 'VeryLazy',
  config = function()
    local c = require('colors')
    require('bufferline').setup({
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
        fill               = { bg = c.bg },
        background         = { bg = c.bg,  fg = c.fg_dim },
        buffer_selected    = { bg = c.sel, fg = c.fg,     bold = true },
        buffer_visible     = { bg = c.bg,  fg = c.fg_dim },
        separator          = { fg = c.bg,  bg = c.bg },
        separator_selected = { fg = c.bg,  bg = c.sel },
        separator_visible  = { fg = c.bg,  bg = c.bg },
        numbers            = { bg = c.bg,  fg = c.bg4 },
        numbers_selected   = { bg = c.sel, fg = c.bg4,    bold = true },
        numbers_visible    = { bg = c.bg,  fg = c.bg4 },
      },
    })
  end,
}
