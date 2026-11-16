local M = {}

local float_win
local restore_origin

local function close_and_restore()
  vim.api.nvim_win_close(float_win, false)
  float_win = nil
  if restore_origin then
    restore_origin()
  end
end

local function enter_insert_if_term()
  if vim.bo.buftype == "terminal" then
    vim.cmd("startinsert")
  end
end

M.close_float = function()
  if float_win and vim.api.nvim_win_is_valid(float_win) then
    close_and_restore()
  end
  float_win = nil
end

M.toggle_max_float = function()
  if float_win and vim.api.nvim_win_is_valid(float_win) then
    close_and_restore()
    enter_insert_if_term()
    return
  end

  local origin_win = vim.api.nvim_get_current_win()
  local w = math.floor(vim.o.columns * 0.9)
  local h_factor = OnNeovide and 0.98 or 0.96
  local h = math.floor(vim.o.lines * h_factor)
  float_win = vim.api.nvim_open_win(vim.api.nvim_get_current_buf(), true, {
    relative = "editor",
    width = w,
    height = h,
    col = math.floor((vim.o.columns - w) / 2),
    row = math.floor((vim.o.lines - h) / 2),
    style = "minimal",
    border = "rounded",
  })

  -- Limitation: Neovim does not reflow the terminal scrollback. Only new output wraps at the float
  -- width. Output from before the float keeps its old width.
  if vim.bo.buftype == "terminal" then
    local gutter = { foldcolumn = "9", signcolumn = "yes:9", number = true, numberwidth = 20 }
    local saved = {}
    for name, value in pairs(gutter) do
      saved[name] = vim.wo[origin_win][name]
      vim.wo[origin_win][name] = value
    end
    restore_origin = function()
      if vim.api.nvim_win_is_valid(origin_win) then
        for name, value in pairs(saved) do
          vim.wo[origin_win][name] = value
        end
      end
      restore_origin = nil
    end
  end

  local backdrop = require("scripts.ui.create-backdrop-window")
  local bd = backdrop.open({ blend = 40 })
  backdrop.link_to_window(float_win, bd)

  enter_insert_if_term()
end

return M
