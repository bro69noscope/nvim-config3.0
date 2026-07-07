local M = {}
local original_dimensions = {}

M.restore_window = function()
  local win_id = vim.api.nvim_get_current_win()
  if original_dimensions[win_id] then
    vim.api.nvim_win_set_width(win_id, original_dimensions[win_id].width)
    vim.api.nvim_win_set_height(win_id, original_dimensions[win_id].height)
    original_dimensions[win_id] = nil
  end
end

M.set_window = function()
  local win_id = vim.api.nvim_get_current_win()
  original_dimensions[win_id] = {
    width = vim.api.nvim_win_get_width(win_id),
    height = vim.api.nvim_win_get_height(win_id),
  }
  return win_id
end

M.maximize_window = function()
  M.restore_window()
  M.set_window()
  vim.cmd("wincmd _")
  vim.cmd("wincmd |")
end

M.half_size_window = function()
  M.restore_window()
  local win_id = M.set_window()
  M.maximize_window()
  local max_width = vim.api.nvim_win_get_width(win_id)
  local max_height = vim.api.nvim_win_get_height(win_id)
  vim.api.nvim_win_set_width(win_id, math.floor(max_width / 2))
  vim.api.nvim_win_set_height(win_id, math.floor(max_height / 2))
end

return M
