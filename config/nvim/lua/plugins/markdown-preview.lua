return {
  'iamcco/markdown-preview.nvim',
  cmd = { 'MarkdownPreview', 'MarkdownPreviewStop', 'MarkdownPreviewToggle' },
  ft = { 'markdown' },
  -- downloads the prebuilt preview binary into app/bin (no node build needed).
  -- the plugin's package.json version is stale, so mkdp#util#install() passes a
  -- bad tag and 404s; install.sh with no arg grabs the latest release, which works.
  build = 'cd app && ./install.sh',
  init = function()
    vim.g.mkdp_filetypes = { 'markdown' }
    vim.g.mkdp_theme = 'dark'
    vim.g.mkdp_auto_close = 0 -- keep the preview open when you leave the markdown buffer

    -- One shared preview window for all markdown buffers instead of one-per-file;
    -- it re-points to whatever buffer you focus (BufEnter). With the new-window func
    -- below, that means: a new Firefox window on first open, then it follows you.
    vim.g.mkdp_combine_preview = 1
    vim.g.mkdp_combine_preview_auto_refresh = 1

    -- Always open the preview in a new Firefox window. g:mkdp_browser only takes a
    -- bare binary (no flags), so use browserfunc to pass --new-window.
    vim.g.mkdp_browserfunc = 'MkdpOpenInNewWindow'
    vim.cmd([[
      function! MkdpOpenInNewWindow(url) abort
        call jobstart(['firefox', '--new-window', a:url], {'detached': v:true})
      endfunction
    ]])

    -- buffer-local toggle for markdown files
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      callback = function(args)
        vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<cr>', {
          buffer = args.buf,
          desc = 'Markdown [P]review toggle',
        })
      end,
    })
  end,
}
