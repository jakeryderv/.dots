-- crates.io lookups in Cargo.toml: outdated-version markers, version/feature
-- completion and upgrade code actions. Its in-process language server feeds
-- blink's existing 'lsp' source, so no extra completion source is needed.
-- tombi still owns TOML structure/schema checks and formatting.
return {
  'saecki/crates.nvim',
  version = '^0.7',
  event = { 'BufRead Cargo.toml' },
  opts = {
    lsp = {
      enabled = true,
      actions = true,
      completion = true,
      hover = true,
    },
  },
}
