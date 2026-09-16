"""Exercise the Neovim Herdr loader without a server, plugins, or user config."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("nvim"), "Neovim is not installed")
class HerdrNavigationTests(unittest.TestCase):
    def test_loader_and_fallbacks(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            editor = root / "editor"
            editor.mkdir()
            (editor / "nvim.lua").write_text("vim.g.herdr_bridge_loaded = true\n")
            script = root / "test.lua"
            script.write_text(
                r"""
local spec = dofile('config/nvim/lua/plugins/vim-tmux-navigator.lua')
assert(spec.lazy == false, 'navigation must not be overwritten by lazy handlers')
spec.init()
assert(vim.g.tmux_navigator_no_mappings == 1)
assert(#spec.keys == 5, 'preserve four tmux directions and previous-window binding')
assert(spec.keys[5][1] == '<c-\\>')

local calls, warnings = 0, 0
local result = { code = 0, stdout = '' }
vim.system = function(argv, opts)
  calls = calls + 1
  assert(argv[1] == (vim.env.HERDR_BIN_PATH ~= '' and vim.env.HERDR_BIN_PATH or 'herdr'))
  assert(table.concat(argv, ' ', 2) == 'plugin list --plugin vim-herdr-navigation --json')
  assert(opts.text)
  return { wait = function(_, timeout)
    assert(timeout == 2000)
    return result
  end }
end
vim.schedule = function(fn) fn() end
vim.notify = function(_, level)
  assert(level == vim.log.levels.WARN)
  warnings = warnings + 1
end

-- Ordinary and tmux-launched Neovim must not query Herdr at all.
vim.env.HERDR_PANE_ID = nil
spec.config()
vim.env.TMUX = '/fake-tmux,1,0'
spec.config()
assert(calls == 0 and warnings == 0)

vim.env.HERDR_PANE_ID = 'test:p1'
vim.env.HERDR_BIN_PATH = '/custom/herdr'
local plugin = { enabled = true, plugin_root = vim.env.TEST_PLUGIN_ROOT }
local function response(plugins)
  result = { code = 0, stdout = vim.json.encode({ result = { plugins = plugins } }) }
end
response({ plugin })
spec.config()
assert(vim.g.herdr_bridge_loaded == true and warnings == 0)
vim.g.herdr_bridge_loaded = false

-- Missing/disabled plugin, missing editor, malformed JSON, and failed CLI
-- must leave the original mappings available and warn instead of crashing.
response({})
spec.config()
plugin.enabled = false
response({ plugin })
spec.config()
plugin.enabled = true
plugin.plugin_root = vim.env.TEST_PLUGIN_ROOT .. '/missing'
response({ plugin })
spec.config()
result = { code = 0, stdout = 'not JSON' }
spec.config()
result = { code = 1, stdout = '' }
spec.config()
assert(warnings == 5 and vim.g.herdr_bridge_loaded == false)

-- An empty binary override must fall back to PATH.
vim.env.HERDR_BIN_PATH = ''
plugin.plugin_root = vim.env.TEST_PLUGIN_ROOT
response({ plugin })
spec.config()
assert(vim.g.herdr_bridge_loaded == true)
"""
            )
            env = {**os.environ, "TEST_PLUGIN_ROOT": str(root)}
            for key in ("HERDR_PANE_ID", "HERDR_BIN_PATH", "TMUX"):
                env.pop(key, None)
            result = subprocess.run(
                ["nvim", "--headless", "-u", "NONE", "-i", "NONE", "-l", str(script)],
                cwd=ROOT,
                env=env,
                capture_output=True,
                text=True,
                timeout=20,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
