-- Quarto documents (.qmd). quarto-nvim adds :QuartoPreview and starts
-- otter.nvim, which runs the regular language servers (ty, ruff, bashls,
-- yamlls for the front matter...) on the code cells, so hover, gd,
-- diagnostics and blink completion work inside them.
--
-- <leader>q is for the Quarto CLI's own commands, which also take plain .md
-- and .ipynb files; markdown tools (render-markdown, img-clip) keep
-- <leader>m in .qmd buffers too. markdown-preview stays .md-only: it renders
-- Quarto syntax (callouts, {mermaid}) as plain text.
--
-- Running cells from the editor (slime/molten) is off; :QuartoPreview
-- executes them on render.

-- Next/previous code cell: jumps to the first line inside the fence.
local function goto_cell(dir)
  local tree = vim.treesitter.get_parser(0):parse()[1]
  local query = vim.treesitter.query.parse('markdown', '(fenced_code_block) @cell')
  for _ = 1, vim.v.count1 do
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local target
    for _, node in query:iter_captures(tree:root(), 0) do
      local content = node:range() + 1
      if dir > 0 and content > row and (not target or content < target) then
        target = content
      elseif dir < 0 and content < row and (not target or content > target) then
        target = content
      end
    end
    if not target then
      return
    end
    vim.api.nvim_win_set_cursor(0, { target + 1, 0 })
  end
end

-- `quarto render` in the background (the first format in the front matter),
-- reporting the output file or the error.
local function render()
  local file = vim.api.nvim_buf_get_name(0)
  vim.cmd.update()
  vim.notify('Rendering ' .. vim.fs.basename(file) .. '...', vim.log.levels.INFO, { title = 'Quarto' })
  vim.system({ 'quarto', 'render', file }, { text = true }, function(out)
    -- Quarto reports progress and the output path on stderr.
    local log = (out.stderr or '') .. (out.stdout or '')
    vim.schedule(function()
      if out.code == 0 then
        local output = log:match('Output created: ([^\n]+)') or 'done'
        vim.notify('Output created: ' .. output, vim.log.levels.INFO, { title = 'Quarto' })
      else
        local tail = vim.list_slice(vim.split(vim.trim(log), '\n'), -15)
        vim.notify(table.concat(tail, '\n'), vim.log.levels.ERROR, { title = 'Quarto render failed' })
      end
    end)
  end)
end

-- Buffer-local keys for anything the Quarto CLI renders.
local function quarto_keys(buf)
  local map = function(keys, func, desc)
    vim.keymap.set('n', keys, func, { buffer = buf, desc = desc })
  end
  map('<leader>qp', '<cmd>QuartoPreview<cr>', 'Quarto: Preview in browser')
  map('<leader>qc', '<cmd>QuartoClosePreview<cr>', 'Quarto: Close preview')
  map('<leader>qr', render, 'Quarto: Render file')
  map('<leader>qh', ':QuartoHelp ', 'Quarto: Search docs')
end

-- Cell editing for .qmd: `ic`/`ac` (mini.ai) select a cell's code / the whole
-- fenced cell, using quarto-nvim's @codechunk textobjects queries; ]x / [x move
-- between cells (]c / [c are gitsigns hunks).
local function cell_keys(buf)
  local spec = require('mini.ai').gen_spec.treesitter({ a = '@codechunk.outer', i = '@codechunk.inner' })
  vim.b[buf].miniai_config = { custom_textobjects = { c = spec } }
  local map = function(keys, func, desc)
    vim.keymap.set({ 'n', 'x', 'o' }, keys, func, { buffer = buf, desc = desc })
  end
  map(']x', function()
    goto_cell(1)
  end, 'Next code cell')
  map('[x', function()
    goto_cell(-1)
  end, 'Prev code cell')
end

return {
  'quarto-dev/quarto-nvim',
  ft = { 'quarto' },
  cmd = { 'QuartoPreview', 'QuartoClosePreview', 'QuartoHelp' },
  dependencies = {
    'jmbuhr/otter.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    codeRunner = { enabled = false },
  },
  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('quarto-keys', { clear = true }),
      -- .ipynb files open as json.
      pattern = { 'quarto', 'markdown', 'json' },
      callback = function(args)
        if args.match == 'json' and not args.file:match('%.ipynb$') then
          return
        end
        quarto_keys(args.buf)
        if args.match == 'quarto' then
          cell_keys(args.buf)
        end
      end,
    })
  end,
}
