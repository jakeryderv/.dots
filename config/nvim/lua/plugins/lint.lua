return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local lint = require('lint')
    lint.linters_by_ft = {
      -- ruff is system-managed (not via Mason). Install with: uv tool install ruff
      python = { 'ruff' },
      -- No shell entry on purpose: bash-language-server runs shellcheck itself,
      -- on every change rather than only on write. Listing it here too produced
      -- every warning twice (namespaces 'shellcheck' + 'nvim.lsp.bashls.N').
      -- shellcheck stays in mason-tool-installer -- bashls shells out to it.
      -- Config lives in .shellcheckrc, which bashls, nvim-lint and CI all read.
      javascript = { 'eslint_d' },
      javascriptreact = { 'eslint_d' },
      typescript = { 'eslint_d' },
      typescriptreact = { 'eslint_d' },
    }
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = vim.api.nvim_create_augroup('lint', { clear = true }),
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
