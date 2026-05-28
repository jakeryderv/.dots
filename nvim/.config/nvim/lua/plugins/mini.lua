return {
  'echasnovski/mini.nvim',
  config = function()
    require('mini.ai').setup { n_lines = 500 }
    require('mini.surround').setup()
    require('mini.indentscope').setup {
      symbol = '│',
      options = { try_as_border = true },
      draw = { animation = require('mini.indentscope').gen_animation.none() },
    }

    -- Disabled everywhere by default — only enabled on code filetypes
    vim.g.miniindentscope_disable = true

    local enable_fts = {
      'python', 'lua', 'rust', 'go', 'c', 'cpp', 'java', 'ruby', 'php',
      'javascript', 'javascriptreact', 'typescript', 'typescriptreact',
      'html', 'css', 'scss', 'sass', 'less', 'vue', 'svelte',
      'sh', 'bash', 'zsh', 'fish',
      'yaml', 'toml', 'json', 'jsonc', 'xml',
      'vim', 'sql', 'dockerfile', 'make',
    }
    vim.api.nvim_create_autocmd('FileType', {
      pattern = enable_fts,
      callback = function(args)
        vim.b[args.buf].miniindentscope_disable = false
      end,
    })

    -- mini.statusline removed in favor of lualine.nvim
  end,
}
