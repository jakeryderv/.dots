-- Telescope pickers that insert plain markdown links to other markdown files
-- in the repo: [name](/path/to/file.md) and [Heading](/path/to/file.md#slug).
-- Paths start at the vault root (see M.root), a form both GitHub and
-- marksman resolve. In visual mode the selected text becomes the link text.
local M = {}

-- Vault root markers, shared with marksman (lsp.lua), <CR> link following
-- (autocmds.lua) and image paste (img-clip.lua). An explicit root
-- (.obsidian / .marksman.toml) wins over the enclosing git repo; the nested
-- table gives those two equal priority, so the nearest one is used.
M.root_markers = { { '.obsidian', '.marksman.toml' }, '.git' }

--- Vault root for a buffer, or nil outside any vault.
function M.root(buf)
  return vim.fs.root(buf or 0, M.root_markers)
end

-- Markdown files, honouring .gitignore (so untracked notes are included but
-- node_modules and build output are not). .trash is Obsidian's deleted notes.
local FD = { 'fd', '--type', 'f', '--extension', 'md', '--hidden', '--exclude', '.git', '--exclude', '.trash' }

-- GitHub's heading anchor: lowercase, punctuation dropped, each space a '-'.
-- Bytes >= 0x80 are kept so non-ASCII letters survive.
local function slug(text)
  return (text:lower():gsub('[^%w%s%-_\128-\255]', ''):gsub(' ', '-'))
end

local function link_path(rel, anchor)
  local path = '/' .. rel .. (anchor and ('#' .. anchor) or '')
  -- CommonMark needs <...> around a destination containing spaces.
  return path:find(' ') and ('<' .. path .. '>') or path
end

-- Capture the visual selection (charwise, as typed) so the picker can replace
-- it later. Returns nil outside visual mode.
local function take_selection()
  local mode = vim.fn.mode()
  if not mode:match('^[vV\22]') then
    return nil
  end
  local region = vim.fn.getregionpos(vim.fn.getpos('v'), vim.fn.getpos('.'), { type = mode })
  local text = table.concat(vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'), { type = mode }), ' ')
  vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'nx', false)
  local first, last = region[1][1], region[#region][2]
  return { text = text, srow = first[2] - 1, scol = first[3] - 1, erow = last[2] - 1, ecol = last[3] }
end

local function insert(buf, win, selection, label, target)
  local text = ('[%s](%s)'):format(selection and selection.text or label, target)
  if selection then
    vim.api.nvim_buf_set_text(buf, selection.srow, selection.scol, selection.erow, selection.ecol, { text })
  else
    vim.api.nvim_win_call(win, function()
      vim.api.nvim_put({ text }, 'c', true, true)
    end)
  end
end

local function root_or_warn()
  local root = M.root(0)
  if not root then
    vim.notify('Markdown links: not inside a vault or git repository', vim.log.levels.WARN)
  end
  return root
end

-- Shared Telescope plumbing: run `picker` and call on_pick(entry) on <CR>.
local function attach(on_pick)
  return function(prompt_bufnr)
    local actions = require('telescope.actions')
    actions.select_default:replace(function()
      local entry = require('telescope.actions.state').get_selected_entry()
      actions.close(prompt_bufnr)
      if entry then
        on_pick(entry)
      end
    end)
    return true
  end
end

function M.pick_file()
  local root = root_or_warn()
  if not root then
    return
  end
  local buf, win, selection = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win(), take_selection()
  require('telescope.builtin').find_files({
    prompt_title = 'Link to file',
    cwd = root,
    find_command = FD,
    attach_mappings = attach(function(entry)
      local rel = entry.value:gsub('^%./', '')
      insert(buf, win, selection, vim.fn.fnamemodify(rel, ':t:r'), link_path(rel))
    end),
  })
end

-- Headings in a markdown file's lines, skipping fenced code blocks (shell
-- comments in a ```bash block are not headings). Duplicate headings get
-- GitHub's -1, -2 ... anchor suffixes. Also used by <CR> to follow #anchors.
function M.headings(lines)
  local headings, fence, seen = {}, nil, {}
  for lnum, line in ipairs(lines) do
    local marker = line:match('^%s*(```+)') or line:match('^%s*(~~~+)')
    if marker and (not fence or marker:sub(1, 1) == fence:sub(1, 1) and #marker >= #fence) then
      fence = not fence and marker or nil
    elseif not fence then
      local hashes, text = line:match('^(#+)%s+(.-)%s*#*%s*$')
      if hashes and #hashes <= 6 and text ~= '' then
        local anchor = slug(text)
        local n = seen[anchor]
        seen[anchor] = (n or 0) + 1
        table.insert(headings, { lnum = lnum, text = text, level = #hashes, anchor = n and (anchor .. '-' .. n) or anchor })
      end
    end
  end
  return headings
end

local function collect_headings(root)
  local all = {}
  for _, rel in ipairs(vim.fn.systemlist(vim.list_extend(vim.list_slice(FD), { '--base-directory', root }))) do
    for _, h in ipairs(M.headings(vim.fn.readfile(root .. '/' .. rel))) do
      h.rel = rel
      table.insert(all, h)
    end
  end
  return all
end

function M.pick_heading()
  local root = root_or_warn()
  if not root then
    return
  end
  local buf, win, selection = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win(), take_selection()
  local current = vim.api.nvim_buf_get_name(buf)
  local conf = require('telescope.config').values
  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Link to heading',
      finder = require('telescope.finders').new_table({
        results = collect_headings(root),
        entry_maker = function(h)
          local display = ('%s  %s %s'):format(h.rel, ('#'):rep(h.level), h.text)
          return {
            value = h,
            display = display,
            ordinal = h.rel .. ' ' .. h.text,
            filename = root .. '/' .. h.rel,
            lnum = h.lnum,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = conf.grep_previewer({}),
      attach_mappings = attach(function(entry)
        local h = entry.value
        -- A heading in this same file links as a bare #anchor.
        local target = root .. '/' .. h.rel == current and ('#' .. h.anchor) or link_path(h.rel, h.anchor)
        insert(buf, win, selection, h.text, target)
      end),
    })
    :find()
end

return M
