return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local lint = require('lint')
    lint.linters_by_ft = {
      -- Ruff comes from uv; eslint_d comes from the selected nvm Node's npm.
      python = { 'ruff' },
      -- No shell entry on purpose: bash-language-server runs shellcheck itself,
      -- on every change rather than only on write. Listing it here too produced
      -- every warning twice (namespaces 'shellcheck' + 'nvim.lsp.bashls.N').
      -- bashls shells out to shellcheck on PATH, so `dots check` and the
      -- editor run the same locally installed binary.
      -- Config lives in .shellcheckrc, which bashls, nvim-lint and CI all read.
      javascript = { 'eslint_d' },
      javascriptreact = { 'eslint_d' },
      typescript = { 'eslint_d' },
      typescriptreact = { 'eslint_d' },
    }
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = vim.api.nvim_create_augroup('lint', { clear = true }),
      callback = function(args)
        lint.try_lint()
        -- actionlint only understands GitHub workflow files, so it is keyed on
        -- the path rather than listed under the generic yaml filetype.
        if vim.api.nvim_buf_get_name(args.buf):match('/%.github/workflows/[^/]+%.ya?ml$') then
          lint.try_lint('actionlint')
        end
      end,
    })
  end,
}
