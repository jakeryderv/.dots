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

    local disable_fts = {
      'snacks_dashboard', 'dashboard', 'starter', 'alpha',
      'help', 'man', 'lazy', 'mason', 'lspinfo', 'checkhealth',
      'noice', 'notify', 'NvimTree', 'neo-tree', 'oil',
      'TelescopePrompt', 'TelescopeResults', 'Trouble', 'trouble',
      'toggleterm', 'gitcommit', 'markdown',
    }
    vim.api.nvim_create_autocmd({ 'FileType', 'BufWinEnter' }, {
      pattern = disable_fts,
      callback = function(args)
        vim.b[args.buf].miniindentscope_disable = true
        local ok, ind = pcall(require, 'mini.indentscope')
        if ok and ind.undraw then pcall(ind.undraw) end
      end,
    })

    -- mini.statusline removed in favor of lualine.nvim
  end,
}
