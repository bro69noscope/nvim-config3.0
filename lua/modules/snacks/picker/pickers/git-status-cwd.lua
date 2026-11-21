local M = {}

---Git status scoped to cwd.
M.open = function()
  local cwd = vim.fs.normalize(vim.uv.cwd())
  Snacks.picker.git_status({
    transform = function(item)
      local abs = vim.fs.normalize(item.cwd .. "/" .. item.file)
      return vim.startswith(abs, cwd .. "/")
    end,
  })
end

return M
