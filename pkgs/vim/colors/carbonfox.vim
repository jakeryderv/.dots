" carbonfox for classic Vim.
"
" Hand-written to match what nightfox.nvim's carbonfox renders in Neovim, so
" the two editors agree. Values were read from a running Neovim rather than
" copied from the palette file -- several groups (CursorLine #353535, the diff
" backgrounds) use shades that are not entries in nvim/lua/colors.lua.
"
" Vim ships no carbonfox, and its built-in defaults live in two places: the
" compiled binary (UI groups) and $VIMRUNTIME/syntax/syncolor.vim (syntax
" groups, e.g. Comment guifg=#80a0ff). This file replaces both.
"
" cterm values use carbonfox's ANSI slot numbers rather than 256-colour
" approximations, because the terminal palette IS carbonfox (see
" ghostty/carbonfox.ghostty). So without 'termguicolors' the colours still
" resolve correctly through the palette, just with less precision.
"
" Normal is deliberately left untouched: Vim's default leaves it cleared, so
" the terminal's background and foreground show through and Ghostty's
" background image stays visible.

hi clear
if exists('syntax_on')
  syntax reset
endif

let g:colors_name = 'carbonfox'

" ---------------------------------------------------------------- syntax ---
hi Comment    guifg=#6e6f70 ctermfg=8  gui=NONE      cterm=NONE
hi Constant   guifg=#5ae0df ctermfg=11 gui=NONE      cterm=NONE
hi String     guifg=#25be6a ctermfg=2  gui=NONE      cterm=NONE
hi Character  guifg=#25be6a ctermfg=2  gui=NONE      cterm=NONE
hi Number     guifg=#3ddbd9 ctermfg=11 gui=NONE      cterm=NONE
hi Boolean    guifg=#3ddbd9 ctermfg=11 gui=NONE      cterm=NONE
hi Float      guifg=#3ddbd9 ctermfg=11 gui=NONE      cterm=NONE
hi Identifier guifg=#33b1ff ctermfg=6  gui=NONE      cterm=NONE
hi Function   guifg=#8cb6ff ctermfg=12 gui=NONE      cterm=NONE
hi Statement  guifg=#be95ff ctermfg=5  gui=NONE      cterm=NONE
hi Conditional guifg=#be95ff ctermfg=5 gui=NONE      cterm=NONE
hi Repeat     guifg=#be95ff ctermfg=5  gui=NONE      cterm=NONE
hi Label      guifg=#be95ff ctermfg=5  gui=NONE      cterm=NONE
hi Keyword    guifg=#be95ff ctermfg=5  gui=NONE      cterm=NONE
hi Exception  guifg=#be95ff ctermfg=5  gui=NONE      cterm=NONE
hi Operator   guifg=#b6b8bb ctermfg=7  gui=NONE      cterm=NONE
hi PreProc    guifg=#ff91c1 ctermfg=9  gui=NONE      cterm=NONE
hi Include    guifg=#ff91c1 ctermfg=9  gui=NONE      cterm=NONE
hi Define     guifg=#ff91c1 ctermfg=9  gui=NONE      cterm=NONE
hi Macro      guifg=#ff91c1 ctermfg=9  gui=NONE      cterm=NONE
hi Type       guifg=#08bdba ctermfg=3  gui=NONE      cterm=NONE
hi StorageClass guifg=#08bdba ctermfg=3 gui=NONE     cterm=NONE
hi Structure  guifg=#08bdba ctermfg=3  gui=NONE      cterm=NONE
hi Typedef    guifg=#08bdba ctermfg=3  gui=NONE      cterm=NONE
hi Special    guifg=#8cb6ff ctermfg=12 gui=NONE      cterm=NONE
hi Delimiter  guifg=#b6b8bb ctermfg=7  gui=NONE      cterm=NONE
hi Underlined guifg=NONE    ctermfg=NONE gui=underline cterm=underline
hi Ignore     guifg=#484848 ctermfg=8
hi Error      guifg=#ee5396 ctermfg=1  gui=NONE      cterm=NONE
hi Todo       guifg=#161616 guibg=#78a9ff ctermfg=0 ctermbg=4 gui=bold cterm=bold

" -------------------------------------------------------------------- UI ---
hi Cursor       guifg=#161616 guibg=#f2f4f8
hi CursorLine   guibg=#353535 ctermbg=236 cterm=NONE
hi CursorColumn guibg=#353535 ctermbg=236
hi ColorColumn  guibg=#252525 ctermbg=235
hi LineNr       guifg=#7b7c7e ctermfg=8  gui=NONE cterm=NONE
hi CursorLineNr guifg=#be95ff ctermfg=5  gui=bold cterm=bold
hi SignColumn   guifg=#7b7c7e ctermfg=8  guibg=NONE ctermbg=NONE
hi Folded       guifg=#7b7c7e guibg=#252525 ctermfg=8 ctermbg=235 gui=NONE cterm=NONE
hi FoldColumn   guifg=#7b7c7e ctermfg=8  guibg=NONE ctermbg=NONE
hi VertSplit    guifg=#0c0c0c ctermfg=0  guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi StatusLine   guifg=#b6b8bb guibg=#0c0c0c ctermfg=7 ctermbg=0 gui=NONE cterm=NONE
hi StatusLineNC guifg=#6e6f70 guibg=#0c0c0c ctermfg=8 ctermbg=0 gui=NONE cterm=NONE
hi TabLine      guifg=#6e6f70 guibg=#1c1c1c ctermfg=8 ctermbg=234 gui=NONE cterm=NONE
hi TabLineSel   guifg=#f2f4f8 guibg=#1c1c1c ctermfg=15 ctermbg=234 gui=bold cterm=bold
hi TabLineFill  guibg=#1c1c1c ctermbg=234
hi Visual       guibg=#2a2a2a ctermbg=235 gui=NONE cterm=NONE
hi Search       guifg=#f2f4f8 guibg=#525253 ctermfg=15 ctermbg=240 gui=NONE cterm=NONE
hi IncSearch    guifg=#161616 guibg=#3ddbd9 ctermfg=0  ctermbg=11 gui=NONE cterm=NONE
hi MatchParen   guifg=#be95ff ctermfg=5 guibg=NONE ctermbg=NONE gui=bold cterm=bold
hi Pmenu        guifg=#f2f4f8 guibg=#2a2a2a ctermfg=15 ctermbg=235
hi PmenuSel     guifg=#f2f4f8 guibg=#525253 ctermfg=15 ctermbg=240
hi PmenuSbar    guibg=#252525 ctermbg=235
hi PmenuThumb   guibg=#525253 ctermbg=240
hi WildMenu     guifg=#161616 guibg=#78a9ff ctermfg=0 ctermbg=4
hi Directory    guifg=#8cb6ff ctermfg=12
hi Title        guifg=#8cb6ff ctermfg=12 gui=bold cterm=bold
hi Question     guifg=#25be6a ctermfg=2
hi MoreMsg      guifg=#25be6a ctermfg=2
hi ModeMsg      guifg=#f2f4f8 ctermfg=15 gui=bold cterm=bold
hi WarningMsg   guifg=#be95ff ctermfg=5
hi ErrorMsg     guifg=#ee5396 ctermfg=1
hi Conceal      guifg=#6e6f70 ctermfg=8

" listchars. Vim draws them with SpecialKey and NonText -- there is no
" 'Whitespace' group, that one is a Neovim addition. bg4 stays legible against
" both the normal (#161616) and cursorline (#353535) backgrounds.
hi SpecialKey   guifg=#535353 ctermfg=240 gui=NONE cterm=NONE
hi NonText      guifg=#535353 ctermfg=240 gui=NONE cterm=NONE
hi EndOfBuffer  guifg=#161616 ctermfg=0

" ------------------------------------------------------------------ diff ---
hi DiffAdd    guibg=#172b20 ctermbg=22 guifg=NONE ctermfg=NONE
hi DiffChange guibg=#222833 ctermbg=17 guifg=NONE ctermfg=NONE
hi DiffDelete guibg=#311d26 ctermbg=52 guifg=NONE ctermfg=NONE
hi DiffText   guibg=#1c3c51 ctermbg=24 guifg=NONE ctermfg=NONE

" ---------------------------------------------------------------- spell ----
hi SpellBad   guisp=#ee5396 gui=undercurl cterm=underline ctermfg=1
hi SpellCap   guisp=#78a9ff gui=undercurl cterm=underline ctermfg=4
hi SpellLocal guisp=#08bdba gui=undercurl cterm=underline ctermfg=3
hi SpellRare  guisp=#be95ff gui=undercurl cterm=underline ctermfg=5
