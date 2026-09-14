local M = {}
local open_with_flags = require("modules.snacks.picker.explorer.open-with-flags")

M.toggle = function()
  local win = vim.api.nvim_get_current_win()
  open_with_flags.toggle()
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.schedule(function()
        vim.api.nvim_set_current_win(win)
      end)
    end
  end)
end

vim.api.nvim_create_user_command("ExplorerToggleNoFocus", M.toggle, {})

return M
