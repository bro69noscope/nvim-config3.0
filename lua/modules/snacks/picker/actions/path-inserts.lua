local M = {}

-- Get the file paths of the selected items, or of the current item if no selection
local function selected_paths(picker)
  local paths = {}
  for _, item in ipairs(picker:selected({ fallback = true })) do
    if item.file then
      table.insert(paths, item.file)
    end
  end

  if #paths == 0 then
    vim.notify("No path", vim.log.levels.WARN)
    return nil
  end
  return paths
end

local function insert_path(picker, use_relative, as_python_import)
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

    if as_python_import then
      path = path:gsub("/__init__%.py$", "")
      path = path:gsub("%.py$", "")
      path = path:gsub("/", ".")
      path = path:gsub("^%.", "")
      path = "from " .. path .. " import "
    end

    table.insert(lines, path)
  end

  picker:close()
  -- Insert the paths, one path for each line
  vim.api.nvim_put(lines, "c", false, true)
end

-- Function to copy full path to clipboard
M.clip_full_path = function(picker)
  local paths = selected_paths(picker)
  if paths == nil then
    return
  end

  -- Convert path format (using absolute path)
  for i, path in ipairs(paths) do
    paths[i] = vim.fn.fnamemodify(path, ":p"):gsub("\\", "/")
  end

  local text = table.concat(paths, "\n")
  vim.fn.setreg("+", text)
  vim.notify("clipped:\n" .. text, vim.log.levels.INFO)
end

M.yank_filename = function(picker)
  local names = selected_paths(picker)
  if names == nil then
    return
  end

  for i, path in ipairs(names) do
    names[i] = vim.fn.fnamemodify(path, ":t")
  end

  local text = table.concat(names, "\n")
  vim.fn.setreg("+", text)
  vim.fn.setreg('"', text)
  vim.notify("Yanked: " .. text)
end

-- Register custom actions with Snacks
M.insert_absolute_path = function(picker)
  insert_path(picker, false, false)
end

M.insert_relative_path = function(picker)
  insert_path(picker, true, false)
end

M.insert_python_import_path = function(picker)
  insert_path(picker, true, true)
end

return M
