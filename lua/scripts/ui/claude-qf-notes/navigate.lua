local M = {}

-- these must match the values in the template script:
-- scripts/templates-for-ai-gen/claude-qf-notes.lua
M.NAMESPACE = vim.api.nvim_create_namespace("claude_qf_notes")
local QFLIST_TITLE = "claude_qf_notes"
-- every run of the skill writes a new note set "<NNN>.lua" in this dir; names sort oldest first
M.NOTES_DIR = ".claude-qf-notes"

local function mark_key()
  return Automated_marks.claude_qf_notes_step.key
end

local function is_notes_list(title)
  return vim.startswith(title, QFLIST_TITLE)
end

---@return boolean true when the current quickfix list is the notes list
function M.is_current_list()
  return is_notes_list(vim.fn.getqflist({ title = 0 }).title)
end

local function find_list_nr()
  for nr = vim.fn.getqflist({ nr = "$" }).nr, 1, -1 do
    if is_notes_list(vim.fn.getqflist({ nr = nr, title = 0 }).title) then
      return nr
    end
  end
end

local function normalized_path(name)
  return vim.fs.normalize(vim.fn.fnamemodify(name, ":p"))
end

---@return string[] absolute paths of the note sets, oldest first
local function list_sets()
  local pattern = vim.fs.joinpath(vim.fn.getcwd(), M.NOTES_DIR, "*.lua")
  local paths = vim.tbl_map(vim.fs.normalize, vim.fn.glob(pattern, false, true))
  table.sort(paths)
  return paths
end

---@param path string
---@return string the `TITLE` of the note set, or its file name if it has none
local function set_title(path)
  for _, l in ipairs(vim.fn.readfile(path, "", 5)) do
    local literal = l:match('^local TITLE = (".*")%s*$')
    if literal then
      local chunk = load("return " .. literal, "TITLE", "t", {})
      local ok, title = pcall(chunk or error)
      if ok and type(title) == "string" then
        return title
      end
    end
  end
  return vim.fs.basename(path)
end

---The note set the notes list was last filled from (the template stores its own path in it).
---@return string?
function M.shown_set()
  local nr = find_list_nr()
  if not nr then
    return nil
  end
  local ctx = vim.fn.getqflist({ nr = nr, context = 0 }).context
  return type(ctx) == "table" and ctx.claude_qf_notes_file or nil
end

local function mark_here()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_mark(0, mark_key(), row, col, {})
end

---@param nr integer the notes list (0 for the current list)
---@return integer? index of the step that the mark is on
local function marked_step_idx(nr)
  local mark = vim.api.nvim_get_mark(mark_key(), {})
  if mark[1] == 0 then
    return nil
  end
  local path = normalized_path(mark[4])
  for idx, item in ipairs(vim.fn.getqflist({ nr = nr, items = 0 }).items) do
    if
      item.bufnr > 0
      and item.lnum == mark[1]
      and normalized_path(vim.api.nvim_buf_get_name(item.bufnr)) == path
    then
      return idx
    end
  end
end

---Go to step idx of the current (notes) list, else to the marked step, else to the first step.
---@param idx? integer
local function jump_to_step(idx)
  local size = vim.fn.getqflist({ size = 0 }).size
  if size == 0 then
    return
  end
  idx = idx or marked_step_idx(0) or 1
  -- silent: the virtual lines already show the step text
  vim.cmd("silent " .. math.min(idx, size) .. "cc")
  mark_here()
end

local function show_list(open_qf)
  if open_qf then
    vim.cmd("copen | wincmd p | normal! zz")
  else
    vim.cmd("normal! zz")
  end
end

local seen = { nr = nil, tick = nil, idx = nil }

local function track_step()
  if vim.bo.buftype ~= "" then
    return
  end
  local qf = vim.fn.getqflist({ nr = 0, title = 0, changedtick = 0, idx = 0 })
  if not is_notes_list(qf.title) then
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

local function changed_since_run(path)
  local stat = (vim.uv or vim.loop).fs_stat(path)
  if not stat then
    return false
  end
  return last_run.path ~= path or last_run.sec ~= stat.mtime.sec or last_run.nsec ~= stat.mtime.nsec
end

-- run a note set script: draws the virtual lines and updates or pushes the quickfix list
local function run_set(path)
  -- quicker.nvim lazy-loads on "FileType qf" and refreshes the (by then non-empty) list on load,
  -- which re-runs its BufReadPost editor setup and errors with E95. Load it while the list is
  -- empty.
  pcall(require, "quicker")
  local ok, err = pcall(function()
    vim.cmd("luafile " .. vim.fn.fnameescape(path))
  end)
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR)
    return false
  end
  local stat = (vim.uv or vim.loop).fs_stat(path)
  if stat then
    last_run = { path = path, sec = stat.mtime.sec, nsec = stat.mtime.nsec }
  end
  return true
end

-- clear() keeps the marks without their virtual lines, so only marks with virt_lines count
local function notes_drawn()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    for _, m in ipairs(vim.api.nvim_buf_get_extmarks(b, M.NAMESPACE, 0, -1, { details = true })) do
      if m[4].virt_lines then
        return true
      end
    end
  end
  return false
end

-- last visited step of each note set that was switched away from, by set path
local steps = {}

-- newest set when a set was last shown, so open() can tell when claude has written a new one
local newest_seen = nil

---Show the note set at path and go to its last visited step. Runs the set script when it is not
---the shown set, was written since the last run, or the list or the virtual lines are gone.
---Otherwise just makes the existing list current again (e.g. after a detour into other lists).
---@param path string
---@param open_qf boolean
local function show_set(path, open_qf)
  local sets = list_sets()
  newest_seen = sets[#sets]
  local nr = find_list_nr()
  local shown = M.shown_set()
  local switching = shown ~= nil and shown ~= path
  if switching then
    steps[shown] = marked_step_idx(nr)
  end

  if not nr or shown ~= path or not notes_drawn() or changed_since_run(path) then
    if not run_set(path) then
      return
    end
  else
    vim.cmd("silent " .. nr .. "chistory")
  end
  -- the mark belongs to the set shown before, so only use it when no other set was shown
  jump_to_step(switching and (steps[path] or 1) or nil)
  show_list(open_qf)
end

local function notify_set(path, sets)
  local pos = vim.fn.index(sets, path) + 1
  vim.notify(("claude notes %d/%d: %s"):format(pos, #sets, set_title(path)))
end

local function open_qf_opt(opts)
  return not (opts and opts.copen == false)
end

function M.setup()
  vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("ClaudeNotesNav", { clear = true }),
    callback = track_step,
    desc = "Mark the last visited claude notes quickfix step",
  })
end

---Go to the last visited step of the shown note set, or of the newest set when claude wrote a new
---one since a set was last shown.
---@param opts? { copen?: boolean } copen defaults to true; false skips opening the quickfix window
function M.open(opts)
  local sets = list_sets()
  local newest = sets[#sets]
  if not newest then
    return vim.notify("no claude notes in " .. M.NOTES_DIR, vim.log.levels.WARN)
  end
  local target = M.shown_set()
  if newest ~= newest_seen or not vim.tbl_contains(sets, target) then
    target = newest
  end
  show_set(target, open_qf_opt(opts))
end

---Show the next (delta 1, newer) or previous (delta -1, older) note set.
---@param delta integer
---@param opts? { copen?: boolean }
function M.cycle(delta, opts)
  local sets = list_sets()
  local i = vim.fn.index(sets, M.shown_set()) + 1
  if i == 0 then
    return M.open(opts)
  end
  local target = sets[i + delta]
  if not target then
    return vim.notify(delta > 0 and "no newer claude notes" or "no older claude notes")
  end
  show_set(target, open_qf_opt(opts))
  notify_set(target, sets)
end

---Delete the note set file at path. Hides the notes first when the set is the shown one, so no
---virtual lines stay from a set that is gone.
---@param path string
local function delete_set(path)
  if path == M.shown_set() then
    M.clear()
  end
  steps[path] = nil
  local ok, err = os.remove(path)
  if not ok then
    vim.notify("could not delete " .. path .. ": " .. tostring(err), vim.log.levels.ERROR)
  end
end

---Pick a note set by its title, newest first. <m-d> deletes the selected sets.
---@param opts? { copen?: boolean }
function M.pick(opts)
  if #list_sets() == 0 then
    return vim.notify("no claude notes in " .. M.NOTES_DIR, vim.log.levels.WARN)
  end
  Snacks.picker.pick({
    title = "Claude notes",
    -- a finder (not static items) so the list is read again after a delete
    finder = function()
      local sets = list_sets()
      local shown = M.shown_set()
      local items = {}
      for i = #sets, 1, -1 do
        table.insert(items, { text = set_title(sets[i]), file = sets[i], shown = sets[i] == shown })
      end
      return items
    end,
    actions = {
      delete_notes = function(picker)
        for _, item in ipairs(picker:selected({ fallback = true })) do
          delete_set(item.file)
        end
        picker.list:set_selected()
        picker:find()
      end,
    },
    win = {
      input = { keys = { ["<m-d>"] = { "delete_notes", mode = { "n", "i" } } } },
      list = { keys = { ["<m-d>"] = "delete_notes" } },
    },
    -- keep newest first instead of the default sort by text length
    sort = { fields = { "score:desc", "idx" } },
    format = function(item)
      return {
        { item.shown and "● " or "  ", "Special" },
        { item.text },
        { "  " .. vim.fs.basename(item.file), "Comment" },
      }
    end,
    preview = "file",
    confirm = function(picker, item)
      picker:close()
      if item then
        show_set(item.file, open_qf_opt(opts))
      end
    end,
  })
end

---Hide the virtual lines but keep the marks (same id and position), so nvim keeps tracking line
---additions/deletions and sync-lines.lua can still write them back on save.
function M.clear()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    for _, m in ipairs(vim.api.nvim_buf_get_extmarks(b, M.NAMESPACE, 0, -1, {})) do
      vim.api.nvim_buf_set_extmark(b, M.NAMESPACE, m[2], m[3], { id = m[1] })
    end
  end
  vim.cmd("cclose")
end

return M
