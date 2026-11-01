local M = {}

local function is_hidden_path(rel)
  for part in vim.gsplit(rel, "/", { plain = true }) do
    if part:sub(1, 1) == "." then
      return true
    end
  end
  return false
end

local function in_dir(dir, path)
  dir = dir:gsub("/$", "")
  return path == dir or path:sub(1, #dir + 1) == dir .. "/"
end

local function common_root(dir, file)
  while not in_dir(dir, file) do
    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      return nil
    end
    dir = parent
  end
  return dir
end

function M.reveal_current()
  local win = vim.api.nvim_get_current_win()
  local file = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
  local cwd = vim.fs.normalize(vim.uv.cwd() or ".")

  local picker = Snacks.picker.get({ source = "explorer" })[1]
  local root = vim.fs.normalize(picker and picker:cwd() or cwd)
  local new_root = not in_dir(root, file) and common_root(root, file) or nil

  -- hidden check relative to the root the explorer will end up with
  local base = new_root or root
  local rel = in_dir(base, file) and file:sub(#base:gsub("/$", "") + 2) or file
  local is_hidden = is_hidden_path(rel)
  -- run from the file's own dir so git finds the repo that contains it, not the one for cwd
  local is_ignored = vim
    .system({ "git", "check-ignore", "-q", file }, { cwd = vim.fs.dirname(file) })
    :wait().code == 0

  if picker then
    if is_hidden then
      picker.opts.hidden = true
    end
    if is_ignored then
      picker.opts.ignored = true
    end
    if new_root then
      picker:set_cwd(new_root)
    end
  elseif is_hidden or is_ignored or new_root then
    Snacks.explorer.open({
      cwd = new_root,
      hidden = is_hidden or nil,
      ignored = is_ignored or nil,
    })
  end

  pcall(Snacks.explorer.reveal, { file = file })
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.schedule(function()
        vim.api.nvim_set_current_win(win)
      end)
    end
  end)
end

return M
