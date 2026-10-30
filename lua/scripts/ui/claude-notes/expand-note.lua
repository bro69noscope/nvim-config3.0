local M = {}

local MAX_LINELENGTH = 100
local MAX_FLOAT_WIN_ROWS = 15

local peek_win = nil

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

local function close_peek_on_navigation(win, src_win, src_buf, src_pos)
  local group = vim.api.nvim_create_augroup("ClaudeNotePeek", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter", "WinEnter" }, {
    group = group,
    callback = function()
      if not vim.api.nvim_win_is_valid(win) then
        return true
      end
      local cur = vim.api.nvim_get_current_win()
      if cur == win or vim.api.nvim_win_get_config(cur).relative ~= "" then
        return
      end
      local untouched = cur == src_win
        and vim.api.nvim_win_get_buf(cur) == src_buf
        and vim.deep_equal(vim.api.nvim_win_get_cursor(cur), src_pos)
      if not untouched then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = tostring(win),
    once = true,
    callback = function()
      pcall(vim.api.nvim_del_augroup_by_id, group)
    end,
  })
end

---Show the claude note(s) on the cursor line as real text in a float, so they can be selected
---and grepped. Closes itself once the source window is navigated away from.
function M.peek()
  local ns = require("scripts.ui.claude-notes.navigate").NAMESPACE
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local marks = vim.api.nvim_buf_get_extmarks(0, ns, { row, 0 }, { row, -1 }, { details = true })

  local lines = {}
  for _, m in ipairs(marks) do
    local parts = {}
    for _, vl in ipairs(m[4].virt_lines or {}) do
      local text = ""
      for _, chunk in ipairs(vl) do
        text = text .. chunk[1]
      end
      table.insert(parts, vim.trim(text))
    end
    table.insert(lines, table.concat(parts, " "))
  end
  if #lines == 0 then
    return vim.notify("no claude note on this line", vim.log.levels.INFO)
  end

  if peek_win and vim.api.nvim_win_is_valid(peek_win) then
    vim.api.nvim_win_close(peek_win, true)
  end

  local src_win = vim.api.nvim_get_current_win()
  local src_buf = vim.api.nvim_get_current_buf()
  local src_pos = vim.api.nvim_win_get_cursor(src_win)

  -- hard-wrap into real lines so the width never depends on window options or other plugins
  local wrapped = {}
  for _, l in ipairs(lines) do
    vim.list_extend(wrapped, wrap(l, MAX_LINELENGTH))
  end
  local width = 0
  for _, l in ipairs(wrapped) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, wrapped)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = math.min(#wrapped, MAX_FLOAT_WIN_ROWS),
    style = "minimal",
    border = "rounded",
  })
  vim.wo[win].wrap = false

  peek_win = win

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, desc = "Close note peek" })
  close_peek_on_navigation(win, src_win, src_buf, src_pos)
end

return M
