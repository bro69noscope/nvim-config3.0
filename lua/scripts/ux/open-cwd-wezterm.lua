local M = {}
M.new_cwd_wezterm_tab = function()
  local cwd = vim.fn.getcwd()

  vim.fn.jobstart({
    "wezterm",
    "cli",
    "spawn",
    "--cwd",
    cwd,
  }, { detach = true })
end
return M
