-- rustaceanvim starts rust-analyzer itself (from PATH, i.e. rustup's), so it
-- must NOT also be enabled through lsp.lua, or two instances would attach.
-- Inlay hints and the shared LSP keymaps still come from lsp.lua's LspAttach.
return {
  'mrcjkb/rustaceanvim',
  version = '^9',
  lazy = false, -- lazy-loads itself on the rust filetype
  init = function()
    vim.g.rustaceanvim = {
      server = {
        on_attach = function(_, bufnr)
          local map = function(keys, cmd, desc)
            vim.keymap.set('n', keys, function()
              vim.cmd.RustLsp(cmd)
            end, { buffer = bufnr, desc = 'Rust: ' .. desc })
          end
          map('<leader>rr', 'runnables', 'Runnables')
          map('<leader>rt', 'testables', 'Testables')
          map('<leader>rm', 'expandMacro', 'Expand macro')
          map('<leader>re', 'explainError', 'Explain error')
          map('<leader>rd', 'renderDiagnostic', 'Render diagnostic')
          map('<leader>rc', 'openCargo', 'Open Cargo.toml')
          map('<leader>rp', 'parentModule', 'Parent module')
        end,
        default_settings = {
          ['rust-analyzer'] = {
            check = { command = 'clippy' },
          },
        },
      },
    }
  end,
}
