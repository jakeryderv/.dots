return {
  'saghen/blink.cmp',
  event = 'VimEnter',
  version = '1.*',
  dependencies = {
    {
      'L3MON4D3/LuaSnip',
      version = '2.*',
      build = (function()
        if vim.fn.has('win32') == 1 or vim.fn.executable('make') == 0 then
          return
        end
        return 'make install_jsregexp'
      end)(),
      dependencies = {
        {
          -- Prebuilt snippet collection; loaded into LuaSnip via the VSCode loader
          'rafamadriz/friendly-snippets',
          config = function()
            require('luasnip.loaders.from_vscode').lazy_load()
          end,
        },
      },
      opts = {},
    },
    'folke/lazydev.nvim',
  },
  --- @module 'blink.cmp'
  --- @type blink.cmp.Config
  opts = {
    keymap = { preset = 'super-tab' },
    appearance = { nerd_font_variant = 'mono' },
    completion = {
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'lazydev', 'buffer' },
      providers = {
        lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
      },
    },
    snippets = { preset = 'luasnip' },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
    signature = { enabled = true },
    -- Auto-show the cmdline completion menu as you type (default only shows it
    -- in the cmdwin / on <Tab>). Keymap stays the built-in 'cmdline' preset.
    -- NOTE: wanted bottom-up ordering (best match nearest the cmdline, to match
    -- the Telescope descending setup). blink's `completion.menu.order` already
    -- defaults to { n = 'bottom_up' } for upward menus, but that field is marked
    -- "TODO: implement" upstream and isn't wired up yet -- so the menu renders
    -- top-down for now. It should become bottom-up automatically once blink
    -- implements it; re-check after a `:Lazy update`.
    cmdline = {
      completion = {
        menu = { auto_show = true },
      },
    },
  },
}
