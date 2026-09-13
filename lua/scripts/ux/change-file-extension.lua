local M = {}
local map = require("scripts.ui.whichkey-map").map
local initial_keybind = "<leader>ur"

local ext_map = {
  j = { ext = "json", desc = "JSON", icon = "" },
  l = { ext = "lua", desc = "Lua", icon = "" },
  p = { ext = "py", desc = "Python", icon = "" },
  m = { ext = "md", desc = "Markdown", icon = "" },
  t = { ext = "txt", desc = "Text", icon = "" },
  y = { ext = "yaml", desc = "YAML", icon = "" },
}

M.change_ext = function(ext)
  ext = ext or vim.fn.input("Extension: ")
  if ext == "" then
    return
  end

  local old = vim.api.nvim_buf_get_name(0)
  local new = old:gsub("%.%w+$", "") .. "." .. ext

  vim.cmd("saveas! " .. vim.fn.fnameescape(new))
  vim.cmd("filetype detect")

  if old ~= new and vim.uv.fs_stat(old) then
    vim.loop.fs_unlink(old)
  end
end

M.setup = function()
  for key, entry in pairs(ext_map) do
    map("n", initial_keybind .. key, function()
      M.change_ext(entry.ext)
    end, { desc = "Change ext to ." .. entry.ext, icon = entry.icon })
  end

  map("n", initial_keybind .. ".", function()
    M.change_ext()
  end, { desc = "Prompt for ext.", icon = "" })
end

return M
