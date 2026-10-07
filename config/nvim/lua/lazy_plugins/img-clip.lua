return {
  'HakonHarnes/img-clip.nvim',
  keys = {
    { '<leader>mi', '<cmd>PasteImage<cr>', ft = 'markdown', desc = 'Markdown: Paste image' },
  },
  opts = {
    default = {
      -- Images go to <repo>/notes/assets, matching the notes/ layout in
      -- markdown-oxide vaults. Returned relative to cwd when possible:
      -- img-clip leaves the inserted path untouched when the current file
      -- sits in cwd, so an absolute dir would leak into the link.
      dir_path = function()
        local root = vim.fs.root(0, '.git')
        if not root then
          return 'assets'
        end
        local dir = root .. '/notes/assets'
        return vim.fs.relpath(vim.fn.getcwd(), dir) or dir
      end,
    },
  },
}
