local M = {}

---Files in the nvim config directory.
M.open = function()
  Snacks.picker.files({ cwd = vim.fn.stdpath("config"), title = "Config Files" })
end

return M
