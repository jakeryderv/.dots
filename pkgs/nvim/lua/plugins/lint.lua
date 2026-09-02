return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local lint = require('lint')
    lint.linters_by_ft = {
      -- ruff comes from flake.nix, like eslint_d below.
      python = { 'ruff' },
      -- No shell entry on purpose: bash-language-server runs shellcheck itself,
      -- on every change rather than only on write. Listing it here too produced
      -- every warning twice (namespaces 'shellcheck' + 'nvim.lsp.bashls.N').
      -- shellcheck comes from flake.nix -- bashls shells out to whatever is on
      -- PATH, so `just check` and the editor run the same pinned binary.
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
