local M = {}
M.open_selection_in_explorer = function()
  local vstart = vim.fn.getpos("v")
  local vend = vim.fn.getpos(".")
  local lines = vim.fn.getregion(vstart, vend, { type = vim.fn.mode() })
  local raw = table.concat(lines, "\n")
  vim.cmd("normal! \27") -- <Esc>, exit visual mode
  local path = raw:gsub("[\r\n]", ""):gsub("\\", "/")
  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  if explorer then
    explorer:focus()
    explorer.input:set(path)
    explorer:find()
  else
    Snacks.picker.explorer({ pattern = path })
  end
end
return M
