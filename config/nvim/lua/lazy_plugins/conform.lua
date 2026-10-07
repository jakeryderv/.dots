return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>cf',
      function()
        require('conform').format({ async = true, lsp_format = 'fallback' })
      end,
      mode = '',
      desc = 'Code: Format buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- C/C++ has no single community style: only format when the project
      -- declares one. Returning nil also skips the LSP fallback, which would
      -- otherwise let clangd impose LLVM style.
      local ft = vim.bo[bufnr].filetype
      if ft == 'c' or ft == 'cpp' then
        local style = vim.fs.find({ '.clang-format', '_clang-format' }, {
          upward = true,
          path = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)),
        })
        if #style == 0 then
          return nil
        end
      end
      return {
        -- 500ms was too tight for prettier/prettierd cold starts; bump so
        -- format-on-save doesn't silently fall back to LSP/no-op.
        timeout_ms = 2000,
        lsp_format = 'fallback',
      }
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
      -- Bash files are filetype 'sh' in Neovim (it sets b:is_bash rather than
      -- ft=bash), so a 'bash' key here would never match. shfmt gets no
      -- prepend_args: any formatting flag makes it ignore .editorconfig.
      sh = { 'shfmt' },
      -- Global formatter installation sources are in docs/software.md.
      python = { 'ruff_organize_imports', 'ruff_format' },
      -- rustfmt comes with the rustup toolchain.
      rust = { 'rustfmt' },
      c = { 'clang_format' },
      cpp = { 'clang_format' },
      -- TOML has no entry: the tombi language server formats it through the
      -- lsp_format fallback, so no second copy of tombi is needed on PATH.
      html = { 'prettierd', 'prettier', stop_after_first = true },
      css = { 'prettierd', 'prettier', stop_after_first = true },
      scss = { 'prettierd', 'prettier', stop_after_first = true },
      javascript = { 'prettierd', 'prettier', stop_after_first = true },
      javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      typescript = { 'prettierd', 'prettier', stop_after_first = true },
      typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      json = { 'prettierd', 'prettier', stop_after_first = true },
      jsonc = { 'prettierd', 'prettier', stop_after_first = true },
      yaml = { 'prettierd', 'prettier', stop_after_first = true },
    },
  },
}
