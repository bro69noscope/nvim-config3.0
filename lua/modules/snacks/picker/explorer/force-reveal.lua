local M = {}

local function is_hidden_path(rel)
  for part in vim.gsplit(rel, "/", { plain = true }) do
    if part:sub(1, 1) == "." then
      return true
    end
  end
  return false
end

function M.reveal_current()
  local win = vim.api.nvim_get_current_win()
  local file = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
  local cwd = vim.fs.normalize(vim.uv.cwd())

  local rel = file:sub(1, #cwd) == cwd and file:sub(#cwd + 2) or file
  local is_hidden = is_hidden_path(rel)
  local is_ignored = vim.system({ "git", "check-ignore", "-q", file }, { cwd = cwd }):wait().code
    == 0

  local picker = Snacks.picker.get({ source = "explorer" })[1]
  if picker then
    if is_hidden then
      picker.opts.hidden = true
    end
    if is_ignored then
      picker.opts.ignored = true
    end
  elseif is_hidden or is_ignored then
    Snacks.explorer.open({ hidden = is_hidden or nil, ignored = is_ignored or nil })
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
