-- Obsidian's attachment folder for a vault root, from .obsidian/app.json, or
-- nil when the root isn't an Obsidian vault. '/' or unset means the vault
-- root; './' (optionally './sub') means next to the current file.
local function obsidian_attachments(root)
  local ok, app = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(root .. '/.obsidian/app.json'), '\n'))
  end)
  if not ok or type(app) ~= 'table' then
    return nil
  end
  local setting = app.attachmentFolderPath or '/'
  if setting:match('^%./') or setting == '.' then
    return vim.fs.joinpath(vim.fn.expand('%:p:h'), (setting:gsub('^%.?/?', '')))
  end
  return vim.fs.joinpath(root, (setting:gsub('^/', '')))
end

return {
  'HakonHarnes/img-clip.nvim',
  keys = {
    { '<leader>mi', '<cmd>PasteImage<cr>', ft = 'markdown', desc = 'Markdown: Paste image' },
  },
  opts = {
    default = {
      -- Obsidian vaults: the vault's own attachment folder (attachments/ in
      -- ~/obsidian/main). Other vaults and git repos: <root>/notes/assets,
      -- the usual notes/ folder for project notes.
      -- Returned relative to cwd when possible: img-clip leaves the inserted
      -- path untouched when the current file sits in cwd, so an absolute dir
      -- would leak into the link.
      dir_path = function()
        local root = require('markdown_links').root(0)
        if not root then
          return 'assets'
        end
        local dir = obsidian_attachments(root) or (root .. '/notes/assets')
        return vim.fs.relpath(vim.fn.getcwd(), dir) or dir
      end,
    },
  },
}
