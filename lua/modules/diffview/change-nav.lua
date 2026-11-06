local M = {}

-- Next change, or next file when already on the last change
M.next_change = function()
  local actions = require("diffview.actions")
  local cur_pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd("normal! ]c")
  vim.cmd("normal! zz")
  local new_pos = vim.api.nvim_win_get_cursor(0)
  if cur_pos[1] == new_pos[1] and cur_pos[2] == new_pos[2] then
    local last_change_pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd("normal! G")
    local eof_pos = vim.api.nvim_win_get_cursor(0)
    if last_change_pos[1] == eof_pos[1] and last_change_pos[2] == eof_pos[2] then
      actions.select_next_entry()
    end
  end
end

-- Previous change, or previous file when already on the first change
M.prev_change = function()
  local actions = require("diffview.actions")
  local cur_pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd("normal! [c")
  vim.cmd("normal! zz")
  local new_pos = vim.api.nvim_win_get_cursor(0)
  if cur_pos[1] == new_pos[1] and cur_pos[2] == new_pos[2] then
    local first_change_pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd("normal! gg")
    local bof_pos = vim.api.nvim_win_get_cursor(0)
    if first_change_pos[1] == bof_pos[1] and first_change_pos[2] == bof_pos[2] then
      actions.select_prev_entry()
    end
  end
end

return M
