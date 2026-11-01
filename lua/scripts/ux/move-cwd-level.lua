local M = {}

---@param opts? { look_up?: boolean } look_up: when already at the git root, jump to a parent repo's root (default true)
M.set_cwd_to_project_root = function(opts)
  local look_up = vim.tbl_extend("force", { look_up = true }, opts or {}).look_up

  local cwd = vim.fn.getcwd()
  local root = vim.fs.root(0, ".git")

  if not root then
    vim.notify("No git repository found", vim.log.levels.ERROR)
    return
  end

  -- Already at this root — look for a parent git repo instead
  if look_up and vim.fs.normalize(root) == vim.fs.normalize(cwd) then
    local parent = vim.fs.dirname(root)
    local parent_root = vim.fs.root(parent, ".git")

    if not parent_root then
      vim.notify("No parent git repository found", vim.log.levels.WARN)
      return
    end

    root = parent_root
  end

  vim.cmd("cd " .. vim.fn.fnameescape(root))
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
