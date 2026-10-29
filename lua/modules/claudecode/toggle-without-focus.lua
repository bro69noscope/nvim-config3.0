local M = {}

-- Toggle Claude terminal without moving focus into it when it opens
M.toggle = function()
  if vim.fn.exists(":ClaudeCode") ~= 2 then
    vim.notify("claudecode.nvim is not available (disabled or not installed)", vim.log.levels.ERROR)
    return
  end
  local prev = vim.api.nvim_get_current_win()
  vim.cmd("ClaudeCode")
  local function restore()
    if vim.api.nvim_win_is_valid(prev) and vim.api.nvim_get_current_win() ~= prev then
      vim.api.nvim_set_current_win(prev)
      if vim.bo[vim.api.nvim_win_get_buf(prev)].buftype == "terminal" then
        vim.cmd("startinsert")
      else
        vim.cmd("stopinsert")
      end
    end
  end
  restore()
  vim.schedule(restore) -- terminal may enter insert/focus asynchronously
end

vim.api.nvim_create_user_command("ClaudeCodeToggleNoFocus", M.toggle, {})

return M
