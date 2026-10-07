return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = 'VeryLazy',
  config = function()
    local c = require('colors')
    local bar = c.bg2 -- #1c1c1c, shared bar background with lualine
    local bufferline = require('bufferline')
    -- stylua: ignore
    local highlights = {
      fill               = { bg = bar },
      background         = { bg = bar, fg = c.fg_dim },
      buffer_visible     = { bg = bar, fg = c.fg_mute },
      buffer_selected    = { bg = c.bg3, fg = c.fg, bold = true, italic = false },
      -- The disabled indicator still occupies a blank cell before the filename.
      indicator_selected = { fg = c.bg3, bg = c.bg3 },
      indicator_visible  = { fg = bar, bg = bar },
      -- Hide separator glyphs while keeping the active background continuous.
      separator          = { fg = bar, bg = bar },
      separator_selected = { fg = c.bg3, bg = c.bg3 },
      separator_visible  = { fg = bar, bg = bar },
    }
    -- Give icons, diagnostics, and duplicate-name prefixes the same background
    -- as their filename, so the active buffer forms one continuous block.
    for _, name in ipairs({
      'numbers',
      'diagnostic',
      'hint',
      'hint_diagnostic',
      'info',
      'info_diagnostic',
      'warning',
      'warning_diagnostic',
      'error',
      'error_diagnostic',
      'modified',
      'duplicate',
      'close_button',
    }) do
      highlights[name] = { bg = bar }
      highlights[name .. '_visible'] = { bg = bar }
      highlights[name .. '_selected'] = { bg = c.bg3 }
    end
    bufferline.setup({
      options = {
        mode = 'buffers',
        style_preset = bufferline.style_preset.no_italic,
        -- Apply these custom highlights again after a colorscheme reload.
        themable = false,
        separator_style = 'thin',
        indicator = { style = 'none' },
        always_show_bufferline = true,
        show_buffer_close_icons = false,
        show_close_icon = false,
        color_icons = false,
        diagnostics = 'nvim_lsp',
        offsets = {
          {
            filetype = 'neo-tree',
            text = 'Neo-tree',
            text_align = 'left',
            highlight = { bg = bar, fg = c.fg_dim, bold = false, italic = false },
            separator = false,
          },
        },
      },
      highlights = highlights,
    })
  end,
}
