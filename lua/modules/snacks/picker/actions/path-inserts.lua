local M = {}
local function insert_path(picker, use_relative, as_python_import)
  local item = picker:current()
  if item == nil then
    vim.notify("No selection", vim.log.levels.WARN)
    return
  end

  local path = item.file
  if path == nil then
    vim.notify("No path", vim.log.levels.WARN)
    return
  end

  -- Convert path format
  local function convert_path(p)
    return p:gsub("\\", "/")
  end

  local function get_relative_path(p)
    local relative = vim.fn.fnamemodify(p, ":.")
    return convert_path(relative)
  end

  if use_relative then
    path = get_relative_path(path)
  else
    path = convert_path(path)
  end

  if as_python_import then
    path = path:gsub("/__init__%.py$", "")
    path = path:gsub("%.py$", "")
    path = path:gsub("/", ".")
    path = path:gsub("^%.", "")
    path = "from " .. path .. " import "
  end

  picker:close()
  -- Insert the path
  vim.api.nvim_put({ path }, "", false, true)
end

-- Function to copy full path to clipboard
M.clip_full_path = function(picker)
  local item = picker:current()
  if item == nil then
    vim.notify("No selection", vim.log.levels.WARN)
    return
  end
  local path = item.file
  if path == nil then
    vim.notify("No path", vim.log.levels.WARN)
    return
  end

  -- Convert path format (using absolute path)
  path = vim.fn.fnamemodify(path, ":p")
  path = path:gsub("\\", "/")

  -- Copy to clipboard and close picker
  vim.fn.setreg("+", path)
  vim.notify("Full path copied to clipboard" .. path, vim.log.levels.INFO)
  picker:close()
end

M.yank_filename = function(picker)
  local item = picker:current()

  if not item or not item.file then
    vim.notify("No file selected to yank", vim.log.levels.WARN)
    return
  end

  local filename = vim.fn.fnamemodify(item.file, ":t")
  vim.fn.setreg("+", filename)
  vim.fn.setreg('"', filename)
  vim.notify("Yanked: " .. filename)
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
