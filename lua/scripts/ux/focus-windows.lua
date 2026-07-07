local M = {}

local function focus_window(predicate)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if predicate(win, buf) then
      vim.api.nvim_set_current_win(win)
      return true
    end
  end
  return false
end

M.largest = function()
  local largest_win, largest_area = nil, 0

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      local area = vim.api.nvim_win_get_width(win) * vim.api.nvim_win_get_height(win)
      if area > largest_area then
        largest_area = area
        largest_win = win
      end
    end
  end

  if largest_win then
    vim.api.nvim_set_current_win(largest_win)
  end
end

M.quickfix = function()
  focus_window(function(_, buf)
    return vim.bo[buf].buftype == "quickfix"
  end)
end

M.snacks_explorer = function()
  focus_window(function(_, buf)
    return vim.bo[buf].filetype == "snacks_picker_list"
  end)
end

return M
