local M = {}

-- these must match the values in the template script:
-- scripts/templates-for-ai-gen/claude-notes.lua
M.NAMESPACE = vim.api.nvim_create_namespace("claude_notes")
local QFLIST_TITLE = "claude_notes_qf"
local NOTES_FILE = ".claude-notes.lua"

local function mark_key()
  return Automated_marks.claude_notes_step.key
end

local function find_list_nr()
  for nr = vim.fn.getqflist({ nr = "$" }).nr, 1, -1 do
    if vim.fn.getqflist({ nr = nr, title = 0 }).title == QFLIST_TITLE then
      return nr
    end
  end
end

local function normalized_path(name)
  return vim.fs.normalize(vim.fn.fnamemodify(name, ":p"))
end

local function mark_here()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_mark(0, mark_key(), row, col, {})
end

local function jump_to_marked_step()
  local mark = vim.api.nvim_get_mark(mark_key(), {})
  if mark[1] ~= 0 then
    local path = normalized_path(mark[4])
    for idx, item in ipairs(vim.fn.getqflist()) do
      if
        item.bufnr > 0
        and item.lnum == mark[1]
        and normalized_path(vim.api.nvim_buf_get_name(item.bufnr)) == path
      then
        vim.cmd(idx .. "cc")
        mark_here()
        return
      end
    end
  end
  vim.cmd("cfirst")
  mark_here()
end

local function show_list()
  vim.cmd("copen | wincmd p | normal! zz")
end

local seen = { nr = nil, tick = nil, idx = nil }

local function track_step()
  if vim.bo.buftype ~= "" then
    return
  end
  local qf = vim.fn.getqflist({ nr = 0, title = 0, changedtick = 0, idx = 0 })
  if qf.title ~= QFLIST_TITLE then
    return
  end

  if seen.nr ~= qf.nr or seen.tick ~= qf.changedtick then
    seen = { nr = qf.nr, tick = qf.changedtick, idx = qf.idx }
    return
  end
  if seen.idx == qf.idx then
    return
  end

  local item = vim.fn.getqflist({ items = 0 }).items[qf.idx]
  local row = vim.api.nvim_win_get_cursor(0)[1]
  if item and item.bufnr == vim.api.nvim_get_current_buf() and item.lnum == row then
    mark_here()
    seen.idx = qf.idx
  end
end

local last_run = { path = nil, sec = nil, nsec = nil }

local function stat_notes_file()
  local path = vim.fn.fnamemodify(NOTES_FILE, ":p")
  return path, (vim.uv or vim.loop).fs_stat(path)
end

local function notes_file_changed()
  local path, stat = stat_notes_file()
  if not stat then
    return false
  end
  return last_run.path ~= path or last_run.sec ~= stat.mtime.sec or last_run.nsec ~= stat.mtime.nsec
end

-- run the generated script: draws the virtual lines and updates or pushes the quickfix list
local function run_notes_script()
  -- quicker.nvim lazy-loads on "FileType qf" and refreshes the (by then non-empty) list on load,
  -- which re-runs its BufReadPost editor setup and errors with E95. Load it while the list is
  -- empty.
  pcall(require, "quicker")
  local ok, err = pcall(function()
    vim.cmd("luafile " .. vim.fn.fnameescape(NOTES_FILE))
  end)
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR)
    return false
  end
  local path, stat = stat_notes_file()
  if stat then
    last_run = { path = path, sec = stat.mtime.sec, nsec = stat.mtime.nsec }
  end
  return true
end

local function notes_drawn()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if #vim.api.nvim_buf_get_extmarks(b, M.NAMESPACE, 0, -1, { limit = 1 }) > 0 then
      return true
    end
  end
  return false
end

function M.setup()
  vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("ClaudeNotesNav", { clear = true }),
    callback = track_step,
    desc = "Mark the last visited claude notes quickfix step",
  })
end

---Go to the last visited step of the claude notes. Regenerates the notes from the script when it
---was written since the last run, or when the list or the virtual lines are gone, and otherwise
---just makes the existing list current again (e.g. after a detour into other lists).
function M.open()
  local nr = find_list_nr()
  if (not nr or not notes_drawn() or notes_file_changed()) and run_notes_script() then
    jump_to_marked_step()
    show_list()
    return
  end
  if not nr then
    return
  end
  vim.cmd("silent " .. nr .. "chistory")
  jump_to_marked_step()
  show_list()
end

function M.clear()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_clear_namespace(b, M.NAMESPACE, 0, -1)
  end
  vim.cmd("cclose")
end

return M
