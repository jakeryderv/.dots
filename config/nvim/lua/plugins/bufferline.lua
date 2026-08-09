return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = 'VeryLazy',
  config = function()
    local c = require('colors')
    local bar = c.bg2 -- #1c1c1c, shared bar background with lualine
    require('bufferline').setup({
      options = {
        mode = 'buffers',
        separator_style = 'thin',
        indicator = { style = 'none' },
        always_show_bufferline = true,
        show_buffer_close_icons = false,
        show_close_icon = false,
        diagnostics = 'nvim_lsp',
      },
      highlights = {
        fill               = { bg = bar },
        -- inactive: dim
        background         = { bg = bar, fg = c.fg_dim },
        buffer_visible     = { bg = bar, fg = c.fg_mute },
        -- active: just bright + bold, no marker
        buffer_selected    = { bg = bar, fg = c.fg, bold = true },
        -- separators vanish into the bar for a flat spacing look
        separator          = { fg = bar, bg = bar },
        separator_selected = { fg = bar, bg = bar },
        separator_visible  = { fg = bar, bg = bar },
      },
    })
  end,
}
