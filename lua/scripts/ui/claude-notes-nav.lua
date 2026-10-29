local M = {}

-- must match the title in scripts/templates-for-ai-gen/claude-notes.lua
local QFLIST_TITLE = "claude_notes_qf"

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

function M.setup()
  vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("ClaudeNotesNav", { clear = true }),
    callback = track_step,
    desc = "Mark the last visited claude notes quickfix step",
  })
end

function M.open()
  -- quicker.nvim lazy-loads on "FileType qf" and refreshes the (by then non-empty) list on load,
  -- which re-runs its BufReadPost editor setup and errors with E95. load it while the list is
  -- empty.
  pcall(require, "quicker")
  local ok, err = pcall(function()
    vim.cmd("luafile .claude-notes.lua")
  end)
  if not ok then
    return vim.notify(tostring(err), vim.log.levels.ERROR)
  end
  jump_to_marked_step()
  show_list()
end

function M.resume()
  local nr = find_list_nr()
  if not nr then
    return M.open()
  end
  vim.cmd("silent " .. nr .. "chistory")
  jump_to_marked_step()
  show_list()
end

function M.clear()
  local ns = vim.api.nvim_create_namespace("claude")
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)
  end
end

return M
