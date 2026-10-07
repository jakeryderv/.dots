-- Keymap description convention: '<Area>: <action>', no [B]racket letters,
-- e.g. 'Search: Files', 'LSP: Goto references'. <Area> is the which-key group
-- the key lives under (LSP for the g/gr keys). Telescope's keymap picker
-- (Space s k) shows the full text; which-key strips the prefix, since the
-- group title already says it. Keys outside any group get no prefix.
local AREAS = {
  Code = true,
  Git = true,
  Harpoon = true,
  LSP = true,
  Markdown = true,
  Rust = true,
  Search = true,
  Session = true,
  Toggle = true,
  Trouble = true,
}

return {
  'folke/which-key.nvim',
  event = 'VimEnter',
  opts = {
    delay = 0,
    -- Cap column width: without a max, one long description (built-in gx is
    -- 92 chars) makes every column that wide, so `g` collapses to a single
    -- tall column that no_overlap then shrinks to a couple of rows.
    layout = { width = { min = 20, max = 50 } },
    -- Setting replace.desc replaces which-key's default list (lists aren't
    -- merged), so its defaults are repeated here, followed by the area strip.
    -- Icons are picked from the raw desc, so 'Git: ...' still gets git's icon.
    replace = {
      desc = {
        { '<Plug>%(?(.*)%)?', '%1' },
        { '^%+', '' },
        { '<[cC]md>', '' },
        { '<[cC][rR]>', '' },
        { '<[sS]ilent>', '' },
        { '^lua%s+', '' },
        { '^call%s+', '' },
        { '^:%s*', '' },
        function(desc)
          local area, rest = desc:match('^(%a+): (.+)$')
          return area and AREAS[area] and rest or desc
        end,
      },
    },
    icons = {
      mappings = vim.g.have_nerd_font,
      keys = vim.g.have_nerd_font and {} or {
        Up = '<Up> ',
        Down = '<Down> ',
        Left = '<Left> ',
        Right = '<Right> ',
        C = '<C-…> ',
        M = '<M-…> ',
        D = '<D-…> ',
        S = '<S-…> ',
        CR = '<CR> ',
        Esc = '<Esc> ',
        ScrollWheelDown = '<ScrollWheelDown> ',
        ScrollWheelUp = '<ScrollWheelUp> ',
        NL = '<NL> ',
        BS = '<BS> ',
        Space = '<Space> ',
        Tab = '<Tab> ',
        F1 = '<F1>',
        F2 = '<F2>',
        F3 = '<F3>',
        F4 = '<F4>',
        F5 = '<F5>',
        F6 = '<F6>',
        F7 = '<F7>',
        F8 = '<F8>',
        F9 = '<F9>',
        F10 = '<F10>',
        F11 = '<F11>',
        F12 = '<F12>',
      },
    },
    spec = {
      -- Group names double as the description prefixes listed in AREAS.
      { '<leader>s', group = 'Search' },
      { '<leader>S', group = 'Session' },
      { '<leader>t', group = 'Toggle' },
      { '<leader>g', group = 'Git', mode = { 'n', 'v' } },
      { '<leader>h', group = 'Harpoon' },
      { '<leader>c', group = 'Code' },
      { '<leader>m', group = 'Markdown' },
      { '<leader>r', group = 'Rust' },
      { '<leader>x', group = 'Trouble' },

      -- Descriptions for built-in mappings (entries without a rhs only set the
      -- description). A spec desc wins over the mapping's own, so only list
      -- keys nothing in this config redefines: grr/gri/grt/grA/gO get theirs
      -- from lsp.lua's LspAttach, gra from tiny-code-action.lua.
      { 'gr', group = 'LSP', mode = { 'n', 'x' } },
      { 'grn', desc = 'LSP: Rename' },
      { 'grx', desc = 'LSP: Run codelens' },
      { 'gx', desc = 'Open path/URL', mode = { 'n', 'x' } },
      { '[d', desc = 'Prev diagnostic' },
      { ']d', desc = 'Next diagnostic' },
      { '[D', desc = 'First diagnostic' },
      { ']D', desc = 'Last diagnostic' },
      -- matchit
      { 'g%', desc = 'Cycle back through matches', mode = { 'n', 'x' } },
      { '[%', desc = 'Prev unmatched open', mode = { 'n', 'x' } },
      { ']%', desc = 'Next unmatched close', mode = { 'n', 'x' } },
    },
  },
  config = function(_, opts)
    local wk = require('which-key')
    wk.setup(opts)

    -- Python's ftplugin motions have no descriptions. Added per buffer because
    -- markdown maps [[ / ]] differently, and a global spec would rename those.
    local function python_motions(buf)
      local mode = { 'n', 'x' }
      wk.add({
        { '[[', desc = 'Prev class/def start', buffer = buf, mode = mode },
        { ']]', desc = 'Next class/def start', buffer = buf, mode = mode },
        { '[]', desc = 'Prev class/def end', buffer = buf, mode = mode },
        { '][', desc = 'Next class/def end', buffer = buf, mode = mode },
        { '[m', desc = 'Prev method start', buffer = buf, mode = mode },
        { ']m', desc = 'Next method start', buffer = buf, mode = mode },
        { '[M', desc = 'Prev method end', buffer = buf, mode = mode },
        { ']M', desc = 'Next method end', buffer = buf, mode = mode },
      })
    end
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('which-key-python', { clear = true }),
      pattern = 'python',
      callback = function(args)
        python_motions(args.buf)
      end,
    })
    -- which-key loads on VimEnter, after the FileType of files given on the
    -- command line.
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].filetype == 'python' then
        python_motions(buf)
      end
    end
  end,
}
