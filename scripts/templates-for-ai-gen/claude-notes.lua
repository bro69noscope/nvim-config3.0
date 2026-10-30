local notes = {
  {
    file = "path/to/file.ext",
    line = 10,
    text = "[1] START: what this code does and why it matters",
  },
  {
    file = "path/to/file.ext",
    line = 20,
    text = "[1] END: what it hands off to",
  },
  {
    file = "path/to/other_file.ext",
    line = 5,
    text = "[2] START: single-line location, no end note",
  },
}

-- for proper nvim ui navigation capabilities, these must match in the config with:
-- lua/scripts/ui/claude-notes/navigate.lua
-- this script must be saved as ".claude-notes.lua" (NOTES_FILE in navigate.lua)
local NAMESPACE = vim.api.nvim_create_namespace("claude_notes")
local QFLIST_TITLE = "claude_notes_qf"

for _, b in ipairs(vim.api.nvim_list_bufs()) do
  vim.api.nvim_buf_clear_namespace(b, NAMESPACE, 0, -1)
end

local MAX_WIDTH = 100

local function wrap(text, width)
  local lines = {}
  local current = ""

  for word in text:gmatch("%S+") do
    if current == "" then
      current = word
    elseif vim.fn.strdisplaywidth(current .. " " .. word) <= width then
      current = current .. " " .. word
    else
      table.insert(lines, current)
      current = word
    end
  end

  if current ~= "" then
    table.insert(lines, current)
  end

  return lines
end

local failed = 0
local items = {}

for _, n in ipairs(notes) do
  local path = vim.fn.fnamemodify(n.file, ":p")
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)

  local line = vim.api.nvim_buf_get_lines(buf, n.line - 1, n.line, false)[1] or ""
  local indent = line:match("^%s*")
  local is_end = n.text:find("^%[%d+%] END:") ~= nil
  local width = math.max(MAX_WIDTH - vim.fn.strdisplaywidth(indent), 20)
  local virt_lines = {}

  for _, text in ipairs(wrap(n.text, width)) do
    table.insert(virt_lines, { { indent .. text, "DiagnosticVirtualTextHint" } })
  end

  local ok = pcall(vim.api.nvim_buf_set_extmark, buf, NAMESPACE, n.line - 1, 0, {
    virt_lines = virt_lines,
    virt_lines_above = not is_end,
  })

  if not ok then
    failed = failed + 1
  end

  table.insert(items, { filename = path, lnum = n.line, text = n.text })
end

local list_nr

for nr = vim.fn.getqflist({ nr = "$" }).nr, 1, -1 do
  if vim.fn.getqflist({ nr = nr, title = 0 }).title == QFLIST_TITLE then
    list_nr = nr
    break
  end
end

if list_nr then
  vim.fn.setqflist({}, "r", { nr = list_nr, title = QFLIST_TITLE, items = items })
  vim.cmd("silent " .. list_nr .. "chistory")
else
  vim.fn.setqflist({}, " ", { title = QFLIST_TITLE, items = items })
end

if failed > 0 then
  vim.notify(failed .. " claude note(s) could not be placed", vim.log.levels.WARN)
end
