local M = {}

local toggle_checkbox = function(line)
  if line:find("%[ %]") then
    return (line:gsub("%[ %]", "[x]", 1))
  elseif line:find("%[x%]") then
    return (line:gsub("%[x%]", "[ ]", 1))
  end
  local new, count = line:gsub("^(%s*[-*+]%s)", "%1[ ] ", 1)
  -- Return nil when the line is not a list item.
  return count > 0 and new or nil
end

-- Toggle each line in the range [first, last] (1-indexed, inclusive).
M.toggle_range = function(first, last)
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  local skipped = 0
  for i, line in ipairs(lines) do
    local new = toggle_checkbox(line)
    if new then
      lines[i] = new
    else
      skipped = skipped + 1
    end
  end

  if skipped == #lines then
    vim.notify("No checkbox or list item to toggle", vim.log.levels.WARN)
    return
  end
  vim.api.nvim_buf_set_lines(0, first - 1, last, false, lines)
end

-- Operator function for g@. Nvim sets the '[ and '] marks to the range.
-- The "." command calls it again on the same number of lines.
M.operatorfunc = function()
  M.toggle_range(vim.fn.line("'["), vim.fn.line("']"))
end

-- Return an expr mapping function that sets the operatorfunc and returns `keys`.
M.operator = function(keys)
  return function()
    vim.o.operatorfunc = "v:lua.require'lang.markdown.checkbox'.operatorfunc"
    return keys
  end
end

return M
