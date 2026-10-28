-- LaTeX authoring: latexmk builds, Zathura viewing with SyncTeX, LaTeX text
-- objects and motions, and the math-zone detection the tex autosnippets use
-- (luasnippets/tex.lua). Mappings live under <localleader>l (= <leader>l).
-- Completion, references and chktex come from texlab, grammar from ltex_plus
-- (lsp.lua); formatting is tex-fmt (conform.lua).
return {
  'lervag/vimtex',
  -- VimTeX loads itself on tex files. Lazy-loading it would also hide
  -- :VimtexInverseSearch, which Zathura calls for inverse search.
  lazy = false,
  init = function()
    -- The main zathura method tracks the viewer window with xdotool, which
    -- only works on X11; zathura_simple works everywhere. Choose per session
    -- so the same config suits Wayland and X11 machines.
    local x11 = vim.env.WAYLAND_DISPLAY == nil and vim.fn.executable('xdotool') == 1
    vim.g.vimtex_view_method = x11 and 'zathura' or 'zathura_simple'
    -- Open the quickfix list for errors only; warnings stay available via
    -- <localleader>le.
    vim.g.vimtex_quickfix_open_on_warning = 0
  end,
}
