local M = {}
M.make_window_floating = function()
  local win = vim.api.nvim_get_current_win()
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)

  vim.api.nvim_win_set_config(win, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2) - 1,
    border = "single",
  })
end
return M
