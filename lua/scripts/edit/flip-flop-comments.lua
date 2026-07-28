---Operator function to invert (flip-flop) comment state on each line individually
local function unwrap_cstr(cstr)
  local pos = cstr:find("%%s")
  if not pos then
    return vim.trim(cstr), ""
  end
  local left = vim.trim(cstr:sub(1, pos - 1))
  local right = vim.trim(cstr:sub(pos + 2))
  return left, right
end

local function is_commented(line, left, right)
  local trimmed = vim.trim(line)
  if trimmed == "" then
    return false
  end
  local left_ok = left == "" or trimmed:sub(1, #left) == left
  local right_ok = right == "" or trimmed:sub(-#right) == right
  return left_ok and right_ok
end

local function comment_line(line, left, right)
  local indent, content = line:match("^(%s*)(.*)$")
  if content == "" then
    return line
  end
  local commented = indent .. left .. (left ~= "" and " " or "") .. content
  if right ~= "" then
    commented = commented .. " " .. right
  end
  return commented
end

local function uncomment_line(line, left, right)
  local indent, content = line:match("^(%s*)(.*)$")
  if left ~= "" then
    content = content:gsub("^" .. vim.pesc(left) .. "%s?", "", 1)
  end
  if right ~= "" then
    content = content:gsub("%s?" .. vim.pesc(right) .. "$", "", 1)
  end
  return indent .. content
end

function _G.__flip_flop_comment()
  local s = vim.api.nvim_buf_get_mark(0, "[")
  local e = vim.api.nvim_buf_get_mark(0, "]")
  local start_line, end_line = s[1], e[1]

  local cstr = vim.bo.commentstring
  if not cstr or cstr == "" then
    vim.notify("[flip-flop-comment] no commentstring set for this buffer", vim.log.levels.WARN)
    return
  end
  local left, right = unwrap_cstr(cstr)

  local cursor_position = vim.api.nvim_win_get_cursor(0)
  local vmark_start = vim.api.nvim_buf_get_mark(0, "<")
  local vmark_end = vim.api.nvim_buf_get_mark(0, ">")

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  for i, line in ipairs(lines) do
    if vim.trim(line) ~= "" then
      if is_commented(line, left, right) then
        lines[i] = uncomment_line(line, left, right)
      else
        lines[i] = comment_line(line, left, right)
      end
    end
  end
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)

  vim.api.nvim_win_set_cursor(0, cursor_position)
  vim.api.nvim_buf_set_mark(0, "<", vmark_start[1], vmark_start[2], {})
  vim.api.nvim_buf_set_mark(0, ">", vmark_end[1], vmark_end[2], {})
  vim.o.operatorfunc = "v:lua.__flip_flop_comment"
end
