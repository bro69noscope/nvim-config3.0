local M = {}
local selected_paths = require("modules.snacks.picker.actions.yank-entries").selected_paths

local function insert_path(picker, use_relative)
  local paths = selected_paths(picker)
  if paths == nil then
    return
  end

  local lines = {}
  for _, path in ipairs(paths) do
    if use_relative then
      path = vim.fn.fnamemodify(path, ":.")
    end
    path = path:gsub("\\", "/")

    table.insert(lines, path)
  end

  picker:close()
  -- Insert the paths, one path for each line
  vim.api.nvim_put(lines, "c", false, true)
end

M.insert_absolute_path = function(picker)
  insert_path(picker, false)
end

M.insert_relative_path = function(picker)
  insert_path(picker, true)
end

return M
