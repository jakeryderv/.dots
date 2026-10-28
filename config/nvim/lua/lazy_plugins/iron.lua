-- REPLs in a Neovim terminal (iron.nvim): send lines, motions, selections or
-- `# %%` cells from the buffer to a REPL for its filetype, started in a right
-- split on first use. One REPL per filetype and working directory.
--
-- Python runs IPython through uv, so it needs no global install: inside a uv
-- project it sees the project's dependencies, outside one a bare .venv.
-- Other filetypes fall back to iron's built-in REPL list (whichever binary is
-- installed). The cell keys need block_dividers, so Python only.

local function iron(fn, ...)
  local args = { ... }
  return function()
    require('iron.core')[fn](unpack(args))
  end
end

return {
  'Vigemus/iron.nvim',
  cmd = { 'IronRepl', 'IronRestart', 'IronFocus', 'IronHide', 'IronSend', 'IronAttach', 'IronReplHere', 'IronWatch' },
  keys = {
    { '<leader>ii', '<cmd>IronRepl<cr>', desc = 'REPL: Toggle' },
    { '<leader>ir', '<cmd>IronRestart<cr>', desc = 'REPL: Restart' },
    { '<leader>if', '<cmd>IronFocus<cr>', desc = 'REPL: Focus' },
    { '<leader>ih', '<cmd>IronHide<cr>', desc = 'REPL: Hide' },
    { '<leader>iq', iron('close_repl'), desc = 'REPL: Exit' },
    { '<leader>ic', iron('send', nil, '\3'), desc = 'REPL: Interrupt (Ctrl-C)' },
    { '<leader>is', iron('run_motion', 'send_motion'), desc = 'REPL: Send motion' },
    { '<leader>is', iron('visual_send'), mode = 'x', desc = 'REPL: Send selection' },
    { '<leader>il', iron('send_line'), desc = 'REPL: Send line' },
    { '<leader>ip', iron('send_paragraph'), desc = 'REPL: Send paragraph' },
    { '<leader>iu', iron('send_until_cursor'), desc = 'REPL: Send file up to cursor' },
    { '<leader>ia', iron('send_file'), desc = 'REPL: Send file' },
    { '<leader>ib', iron('send_code_block', false), desc = 'REPL: Send cell' },
    { '<leader>in', iron('send_code_block', true), desc = 'REPL: Send cell, go to next' },
  },
  config = function()
    local view = require('iron.view')
    require('iron.core').setup({
      config = {
        scratch_repl = true,
        repl_open_cmd = view.split.vertical.botright('40%'),
        repl_definition = {
          python = {
            -- --no-autoindent: iron sends the code's own indentation.
            command = { 'uv', 'run', '--with', 'ipython', 'ipython', '--no-autoindent' },
            format = require('iron.fts.common').bracketed_paste_python,
            block_dividers = { '# %%', '#%%' },
          },
        },
      },
    })
  end,
}
