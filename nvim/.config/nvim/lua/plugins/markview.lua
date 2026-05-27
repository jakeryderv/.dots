return {
  'OXY2DEV/markview.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
  ft = { 'markdown', 'norg', 'typst', 'rmd' },
  opts = {
    preview = {
      icon_provider = 'mini',
      modes = { 'n', 'no', 'c' },
      hybrid_modes = { 'n' },
      filetypes = { 'markdown', 'quarto', 'rmd', 'typst' },
    },
    markdown = {
      headings = { shift_width = 0 },
    },
  },
  config = function(_, opts)
    require('markview').setup(opts)

    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'markdown', 'quarto', 'rmd' },
      callback = function(args)
        vim.bo[args.buf].suffixesadd = '.md'

        vim.keymap.set('n', '<CR>', function()
          local line = vim.api.nvim_get_current_line()
          local col = vim.api.nvim_win_get_cursor(0)[2] + 1

          for s, target, e in line:gmatch('()%[%[([^%]|]+)[^%]]*%]%]()') do
            if col >= s and col < e then
              local file = target:match('^([^#]+)') or target
              vim.cmd.edit(vim.fn.fnameescape(file .. '.md'))
              return
            end
          end

          for s, url, e in line:gmatch('()%[[^%]]+%]%(([^%)]+)%)()') do
            if col >= s and col < e then
              if url:match('^https?://') or url:match('^mailto:') then
                vim.ui.open(url)
              else
                local file = url:match('^([^#]+)') or url
                vim.cmd.edit(vim.fn.fnameescape(file))
              end
              return
            end
          end

          vim.cmd('normal! +')
        end, { buffer = args.buf, desc = 'Follow markdown link' })
      end,
    })
  end,
}
