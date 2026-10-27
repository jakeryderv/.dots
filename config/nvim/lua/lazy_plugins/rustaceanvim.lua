-- rustaceanvim starts rust-analyzer itself (from PATH, i.e. rustup's), so it
-- must NOT also be enabled through lsp.lua, or two instances would attach.
-- The shared LSP keymaps still come from lsp.lua's LspAttach; <leader>th is
-- the exception and is defined here.

-- Extra inlay hints that make implicit Rust visible (auto-ref/deref, binding
-- modes, elided lifetimes, closure return types). Too noisy for daily use, so
-- they are a second hint set: <leader>th shows the default set, <leader>rh the
-- learning set, and pressing the key of the set already showing hides hints.
local learning_hints = {
  inlayHints = {
    expressionAdjustmentHints = { enable = 'always' },
    bindingModeHints = { enable = true },
    lifetimeElisionHints = { enable = 'skip_trivial' },
    closureReturnTypeHints = { enable = 'with_block' },
  },
}
-- The same keys at rust-analyzer's defaults (`rust-analyzer --print-config-schema`).
-- Switching off must send these explicitly: `:RustAnalyzer config` writes into
-- rustaceanvim's stored settings, so `reloadSettings` would keep the extras.
local default_hints = {
  inlayHints = {
    expressionAdjustmentHints = { enable = 'never' },
    bindingModeHints = { enable = false },
    lifetimeElisionHints = { enable = 'never' },
    closureReturnTypeHints = { enable = 'never' },
  },
}
-- Which set rust-analyzer is sending. Session-wide, like those stored settings:
-- a rust-analyzer started later for another project inherits the last one.
local learning = false

-- Show the given set, or hide hints if it is already showing. Display is
-- global, matching lsp.lua's <leader>th for other languages.
local function toggle_hints(want_learning)
  if vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }) and learning == want_learning then
    vim.lsp.inlay_hint.enable(false)
    vim.notify('Inlay hints: off')
    return
  end
  if learning ~= want_learning then
    learning = want_learning
    local hints = learning and learning_hints or default_hints
    vim.cmd.RustAnalyzer({ 'config', vim.inspect(hints, { newline = ' ', indent = '' }) })
    -- rust-analyzer applies new settings without sending
    -- workspace/inlayHint/refresh, so drawn hints would stay stale until the
    -- next edit. Deliver that refresh ourselves once it has applied them
    -- (measured at ~15-40ms; 200ms leaves headroom).
    vim.defer_fn(function()
      for _, c in ipairs(vim.lsp.get_clients({ name = 'rust-analyzer' })) do
        local method = 'workspace/inlayHint/refresh'
        vim.lsp.handlers[method](nil, nil, { client_id = c.id, method = method })
      end
    end, 200)
  end
  vim.lsp.inlay_hint.enable(true)
  vim.notify('Inlay hints: ' .. (learning and 'learning' or 'default'))
end

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

          vim.keymap.set('n', '<leader>th', function()
            toggle_hints(false)
          end, { buffer = bufnr, desc = 'Toggle: Inlay hints' })
          vim.keymap.set('n', '<leader>rh', function()
            toggle_hints(true)
          end, { buffer = bufnr, desc = 'Rust: Toggle learning hints' })
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
