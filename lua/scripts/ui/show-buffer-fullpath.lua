local M = {}

local function show_float(text)
  local max_width = math.floor(vim.o.columns * 0.6)
  local width = math.min(#text + 2, max_width)
  local height = math.max(1, math.ceil(#text / width))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
  })

  vim.wo[win].wrap = true

  vim.api.nvim_create_autocmd({ "CursorMoved", "BufLeave", "InsertEnter" }, {
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })
end

local function buffer_path()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return "[No Name]"
  end
  return (path:gsub("\\", "/"))
end

M.show_fullpath_cwd = function()
  local path = buffer_path()

  if path ~= "[No Name]" then
    local cwd = vim.fn.getcwd():gsub("\\", "/")
    if path:sub(1, #cwd + 1) == cwd .. "/" then
      path = "~" .. path:sub(#cwd + 1)
    end
  end

  show_float(path)
end

M.show_fullpath = function()
  show_float(buffer_path())
end

return M
