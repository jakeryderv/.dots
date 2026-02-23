return {
  'NvChad/nvim-colorizer.lua',
  event = { 'BufReadPost', 'BufNewFile' },
  config = function()
    require('colorizer').setup({
      filetypes = {
        '*', -- enable everywhere by default
        css = { css = true, names = true },
        scss = { css = true, names = true },
        html = { names = true },
        lua = { names = true },
        markdown = { names = true },
      },
      user_default_options = {
        RGB = true,
        RRGGBB = true,
        RRGGBBAA = true,
        rgb_fn = true,
        hsl_fn = true,
        css = true,
        css_fn = true,
        mode = 'background', -- paint the text background
        tailwind = false, -- set true if you use Tailwind
      },
    })
  end,
}
