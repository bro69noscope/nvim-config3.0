local M = {}

-- Get the selected items, or the current item if no selection
local function selected_items(picker)
  return picker:selected({ fallback = true })
end

-- Get the absolute file paths of the selected items, or of the current item if no selection
M.selected_paths = function(picker)
  local paths = {}
  for _, item in ipairs(selected_items(picker)) do
    -- Resolves item.file against item.cwd, not against the nvim cwd
    local path = Snacks.picker.util.path(item)
    if path then
      table.insert(paths, path)
    end
  end

  if #paths == 0 then
    vim.notify("No path", vim.log.levels.WARN)
    return nil
  end
  return paths
end

-- Get the main value of an item: the relative path for a file item, else its data or text
local function entry_value(item)
  local path = Snacks.picker.util.path(item)
  if path then
    return (vim.fn.fnamemodify(path, ":."):gsub("\\", "/"))
  end

  if type(item.data) == "string" then
    return item.data
  end
  return item.text
end

local function yank(text)
  vim.fn.setreg("+", text)
  vim.fn.setreg('"', text)
  vim.notify("Yanked:\n" .. text)
end

-- Yank the main value of the selected items, one value for each line
M.yank_entry = function(picker)
  local values = {}
  for _, item in ipairs(selected_items(picker)) do
    local value = entry_value(item)
    if value and value ~= "" then
      table.insert(values, value)
    end
  end

  if #values == 0 then
    vim.notify("No entry", vim.log.levels.WARN)
    return
  end
  yank(table.concat(values, "\n"))
end

-- Function to copy full path to clipboard
M.clip_full_path = function(picker)
  local paths = M.selected_paths(picker)
  if paths == nil then
    return
  end

  -- Convert path format (using absolute path)
  for i, path in ipairs(paths) do
    paths[i] = path:gsub("\\", "/")
  end

  local text = table.concat(paths, "\n")
  vim.fn.setreg("+", text)
  vim.notify("clipped:\n" .. text, vim.log.levels.INFO)
end

M.yank_filename = function(picker)
  local names = M.selected_paths(picker)
  if names == nil then
    return
  end

  for i, path in ipairs(names) do
    names[i] = vim.fn.fnamemodify(path, ":t")
  end

  yank(table.concat(names, "\n"))
end

-- Yank the branch names of the selected git branch items (the commit for a detached HEAD)
M.yank_branch = function(picker)
  local branches = {}
  for _, item in ipairs(selected_items(picker)) do
    local branch = item.branch or item.commit
    if branch then
      table.insert(branches, branch)
    end
  end

  if #branches == 0 then
    vim.notify("No branch", vim.log.levels.WARN)
    return
  end
  yank(table.concat(branches, "\n"))
end

return M
