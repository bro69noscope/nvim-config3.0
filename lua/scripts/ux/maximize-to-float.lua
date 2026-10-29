local M = {}

local float_win

local function enter_insert_if_term()
  if vim.bo.buftype == "terminal" then
    vim.cmd("startinsert")
  end
end

M.close_float = function()
  if float_win and vim.api.nvim_win_is_valid(float_win) then
    vim.api.nvim_win_close(float_win, false)
  end
  float_win = nil
end

M.toggle_max_float = function()
  if float_win and vim.api.nvim_win_is_valid(float_win) then
    vim.api.nvim_win_close(float_win, false)
    float_win = nil
    enter_insert_if_term()
    return
  end

  local w = math.floor(vim.o.columns * 0.9)
  local h = math.floor(vim.o.lines * 0.9)
  float_win = vim.api.nvim_open_win(vim.api.nvim_get_current_buf(), true, {
    relative = "editor",
    width = w,
    height = h,
    col = math.floor((vim.o.columns - w) / 2),
    row = math.floor((vim.o.lines - h) / 2),
    style = "minimal",
    border = "rounded",
  })

  local backdrop = require("scripts.ui.create-backdrop-window")
  local bd = backdrop.open({ blend = 40 })
  backdrop.link_to_window(float_win, bd)

  enter_insert_if_term()
end

return M
