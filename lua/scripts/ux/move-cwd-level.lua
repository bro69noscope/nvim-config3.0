local M = {}
M.set_cwd_to_project_root = function()
  local root = vim.fs.root(0, ".git")

  if not root then
    vim.notify("No git repository found", vim.log.levels.ERROR)
    return
  end

  vim.cmd("cd " .. vim.fn.fnameescape(root))
  vim.notify("cwd: " .. root)
end

M.move_cwd_up_one_level = function()
  local parent = vim.fs.dirname(vim.fn.getcwd())

  if parent then
    vim.cmd("cd " .. vim.fn.fnameescape(parent))
  else
    vim.notify("No parent directory found", vim.log.levels.ERROR)
  end
end

M.move_cwd_down_one_level = function()
  local sep = OnWindows and "\\" or "/"
  local cwd = vim.fn.getcwd()
  local buf_dir = vim.fn.expand("%:p:h")

  local cwd_cmp = OnWindows and cwd:lower() or cwd
  local buf_dir_cmp = OnWindows and buf_dir:lower() or buf_dir

  if buf_dir_cmp:find(cwd_cmp, 1, true) ~= 1 then
    vim.notify("Current buffer is not inside cwd", vim.log.levels.ERROR)
    return
  end

  if #buf_dir <= #cwd then
    vim.notify("Already at buffer directory", vim.log.levels.INFO)
    return
  end

  local relative = buf_dir:sub(#cwd + 2)
  local next_dir = relative:match("^[^" .. vim.pesc(sep) .. "]+")
  if not next_dir then
    vim.notify("Already at buffer directory", vim.log.levels.INFO)
    return
  end

  vim.cmd("cd " .. vim.fn.fnameescape(cwd .. sep .. next_dir))
end
return M
