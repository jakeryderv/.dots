return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'master',
  build = ':TSUpdate',
  main = 'nvim-treesitter.configs',
  lazy = false,
  opts = {
    ensure_installed = {
      'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline',
      'query', 'vim', 'vimdoc',
      'python', 'rust', 'javascript', 'typescript', 'tsx',
      'json', 'jsonc', 'yaml', 'toml',
      'regex', 'comment', 'gitignore', 'gitcommit', 'dockerfile', 'make',
      'css', 'scss', 'latex',
    },
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
  },
}
