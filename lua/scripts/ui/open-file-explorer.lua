-- Utilies for opening main file explorer
local M = {}

M.open_main_explorer = function()
  if MainFileExplorer == "neo-tree" then
    vim.cmd("Neotree show")
  elseif MainFileExplorer == "snacks" then
    local current_win = vim.api.nvim_get_current_win()
    require("modules.snacks.picker.explorer.open-with-flags").open()
    vim.defer_fn(function()
      vim.api.nvim_set_current_win(current_win) -- No other way to set current window after snacks explorer opens
    end, 0)
  end
end

return M
