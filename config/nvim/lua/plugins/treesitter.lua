return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main', -- 'master' is frozen and unsupported on Neovim 0.12+
  lazy = false, -- main branch does not support lazy-loading
  build = ':TSUpdate',
  config = function()
    -- Parsers to keep installed. (main branch has no `auto_install`: to add a
    -- new language later, add it here and run :TSUpdate, or :TSInstall <lang>.)
    require('nvim-treesitter').install {
      'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline',
      'query', 'vim', 'vimdoc',
      'python', 'rust', 'javascript', 'typescript', 'tsx',
      'json', 'yaml', 'toml',
      'regex', 'comment', 'gitignore', 'gitcommit', 'dockerfile', 'make',
      'css', 'scss', 'latex',
    }

    -- 'jsonc' has no standalone parser on the main branch; the json parser
    -- handles jsonc files once registered for that filetype.
    vim.treesitter.language.register('json', 'jsonc')

    -- On main, highlighting/indent are no longer "modules" you enable in setup;
    -- you start them per buffer. Do it for any filetype that has a parser.
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
      callback = function(args)
        -- vim.treesitter.start() resolves the language from the filetype and
        -- errors if no parser is installed -> pcall keeps non-TS filetypes quiet.
        if pcall(vim.treesitter.start, args.buf) then
          -- experimental treesitter-based indentation (replaces the old indent module)
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
