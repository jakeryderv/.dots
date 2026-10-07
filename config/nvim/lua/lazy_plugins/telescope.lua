return {
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable('make') == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },
  config = function()
    require('telescope').setup({
      defaults = {
        winblend = 0,
        borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
        layout_config = {
          prompt_position = 'bottom',
          horizontal = { preview_width = 0.55 },
          width = 0.9,
          height = 0.85,
        },
        sorting_strategy = 'descending',
        prompt_prefix = '  ',
        selection_caret = '  ',
        mappings = {
          i = {
            ['<C-j>'] = require('telescope.actions').move_selection_next,
            ['<C-k>'] = require('telescope.actions').move_selection_previous,
          },
        },
      },
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown({
            sorting_strategy = 'descending',
            layout_config = { prompt_position = 'bottom' },
          }),
        },
      },
    })

    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = 'Search: Help' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = 'Search: Keymaps' })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Search: Files' })
    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = 'Search: Telescope pickers' })
    vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = 'Search: Current word' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = 'Search: Grep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = 'Search: Diagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = 'Search: Resume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = 'Search: Recent files' })
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = 'Find buffers' })

    vim.keymap.set('n', '<leader>/', function()
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown({
        winblend = 0,
        previewer = false,
        sorting_strategy = 'descending',
        layout_config = { prompt_position = 'bottom' },
      }))
    end, { desc = 'Fuzzy find in buffer' })

    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep({
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      })
    end, { desc = 'Search: Grep open files' })

    vim.keymap.set('n', '<leader>sn', function()
      builtin.find_files({ cwd = vim.fn.stdpath('config') })
    end, { desc = 'Search: Neovim config' })
  end,
}
