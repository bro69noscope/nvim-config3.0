local M = {}

M.toggle = function()
  local win = vim.api.nvim_get_current_win()
  Snacks.explorer()
  -- schedule won't work because Snacks seems to refocus the explorer after
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
    end
  end, 10)
end

vim.api.nvim_create_user_command("ExplorerToggleNoFocus", M.toggle, {})

return M
