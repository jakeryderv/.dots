return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = 'VeryLazy',
  opts = function()
    -- start from the carbonfox theme, then match the middle/fill section
    -- (lualine_c / lualine_x) to the bufferline bar background
    local theme = require('lualine.themes.carbonfox')
    local bar = require('colors').bg2 -- #1c1c1c, shared bar background with bufferline
    for _, mode in pairs(theme) do
      if mode.c then
        mode.c.bg = bar
      end
    end
    return {
      options = {
        theme = theme,
        icons_enabled = true,
        component_separators = '|',
        section_separators = '',
        globalstatus = true,
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff' },
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { 'diagnostics', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
    }
  end,
}
