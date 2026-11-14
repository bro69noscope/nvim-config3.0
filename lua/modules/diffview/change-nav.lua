local actions = require("diffview.actions")

local M = {}

local function jump_or_select(jump, edge, select_entry)
  local cur_pos = vim.api.nvim_win_get_cursor(0)
  jump()
  vim.cmd("normal! zz")
  local new_pos = vim.api.nvim_win_get_cursor(0)
  if cur_pos[1] == new_pos[1] and cur_pos[2] == new_pos[2] then
    vim.cmd("normal! " .. edge)
    local edge_pos = vim.api.nvim_win_get_cursor(0)
    if new_pos[1] == edge_pos[1] and new_pos[2] == edge_pos[2] then
      select_entry()
    end
  end
end

-- Next change, or next file when already on the last change
M.next_change = function()
  jump_or_select(function()
    vim.cmd("normal! ]c")
  end, "G", actions.select_next_entry)
end

-- Previous change, or previous file when already on the first change
M.prev_change = function()
  jump_or_select(function()
    vim.cmd("normal! [c")
  end, "gg", actions.select_prev_entry)
end

-- Next conflict, or next file when already on the last conflict
M.next_conflict = function()
  jump_or_select(actions.next_conflict, "G", actions.select_next_entry)
end

-- Previous conflict, or previous file when already on the first conflict
M.prev_conflict = function()
  jump_or_select(actions.prev_conflict, "gg", actions.select_prev_entry)
end

return M
