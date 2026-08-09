return {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl', -- the module is 'ibl', not the repo name
  event = { 'BufReadPost', 'BufNewFile' },
  config = function()
    -- Guide style: 'line' = thin ┊ guides, 'block' = alternating gray bg bands.
    -- Flip this one word (then restart / :Lazy reload) to switch.
    local style = 'line'

    local c = require('colors')
    local hooks = require('ibl.hooks')

    -- Background bands for 'block' style: two near-black grays from the carbonfox
    -- palette, alternating per indent level. Registered as a HIGHLIGHT_SETUP hook
    -- so the bg colors survive colorscheme reloads (harmless when style = 'line').
    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      vim.api.nvim_set_hl(0, 'IblIndentEven', { bg = c.bg2 }) -- #1c1c1c
      vim.api.nvim_set_hl(0, 'IblIndentOdd', { bg = c.bg3 }) -- #252525
    end)
    local bands = { 'IblIndentEven', 'IblIndentOdd' }

    local styles = {
      -- Thin dotted guide on every indent level
      line = {
        indent = { char = '┊' },
        whitespace = {},
      },
      -- Background-block guides: no char, the alternating bg fills do the work
      block = {
        indent = { char = '', highlight = bands },
        whitespace = { highlight = bands, remove_blankline_trail = false },
      },
    }
    local s = styles[style]

    require('ibl').setup({
      indent = s.indent,
      whitespace = s.whitespace,
      -- Solid │ on the current scope (treesitter-based)
      scope = {
        enabled = true,
        char = '│',
        show_start = true,
        show_end = false,
        -- ibl's bundled scope table omits loops/conditionals for Python & Bash
        -- (it only knows their functions/classes), so scope wouldn't follow
        -- if/for/while there. Add the missing treesitter node types per language.
        include = {
          node_type = {
            python = {
              'if_statement', 'elif_clause', 'else_clause',
              'for_statement', 'while_statement', 'with_statement',
              'try_statement', 'except_clause', 'finally_clause',
              'match_statement', 'case_clause',
            },
            bash = {
              'if_statement', 'elif_clause', 'else_clause',
              'for_statement', 'c_style_for_statement', 'while_statement',
              'case_statement',
            },
          },
        },
      },
      -- Normal file buffers only; skip special UIs and prose filetypes
      exclude = {
        filetypes = {
          'help',
          'dashboard',
          'snacks_dashboard',
          'neo-tree',
          'Trouble',
          'trouble',
          'lazy',
          'mason',
          'notify',
          'toggleterm',
          'lspinfo',
          'checkhealth',
          'markdown',
          'text',
        },
        buftypes = { 'terminal', 'nofile', 'quickfix', 'prompt' },
      },
    })
  end,
}
