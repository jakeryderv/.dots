-- Code actions with a diff preview, on gra (Vgra for a whole-line selection).
-- This replaces Neovim's built-in gra; the built-in menu (no preview) stays
-- reachable on grA, mapped in lsp.lua, as a fallback.
return {
  'rachartier/tiny-code-action.nvim',
  keys = {
    {
      'gra',
      function()
        require('tiny-code-action').code_action()
      end,
      mode = { 'n', 'x' },
      desc = 'LSP: Code action',
    },
  },
  opts = {
    -- delta is on PATH (software.md); switch to 'vim' if big fix-alls lag.
    backend = 'delta',
    backend_opts = {
      delta = {
        -- --no-gitconfig: the git config's side-by-side layout wraps badly in
        -- the small preview float (delta can't negate it with a flag), so
        -- skip it and pass the parts we want explicitly.
        args = { '--no-gitconfig', '--line-numbers', '--syntax-theme', 'carbonfox' },
      },
    },
    -- Telescope: large window, fuzzy-filter titles, diff preview below.
    -- To switch back to the compact popup at the cursor, use the buffer
    -- picker instead:
    -- picker = {
    --   'buffer',
    --   opts = {
    --     hotkeys = true,
    --     -- a, b, c... Title-based keys come out as r, rf, ri... because
    --     -- every Ruff action title starts with "Ruff".
    --     hotkeys_mode = 'sequential',
    --     auto_preview = true, -- show the diff of the highlighted action
    --     auto_accept = false, -- a hotkey selects; <CR> applies
    --   },
    -- },
    picker = 'telescope',
  },
}
