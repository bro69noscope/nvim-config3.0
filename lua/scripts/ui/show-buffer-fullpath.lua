local M = {}

local close_active

local function show_float(text)
  if close_active then
    close_active()
  end

  local max_width = math.floor(vim.o.columns * 0.7)
  local width = math.min(#text + 2, max_width)
  local height = math.max(1, math.ceil(#text / width))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2) - 1,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
  })

  vim.wo[win].wrap = true

  local backdrop = require("scripts.ui.create-backdrop-window")
  local backdrop_handle = backdrop.open({ blend = 60 })

  local saved_guicursor = vim.o.guicursor
  vim.api.nvim_set_hl(0, "HiddenCursor", { blend = 100, nocombine = true })
  vim.o.guicursor = "a:HiddenCursor"

  local autocmd_id
  local function close()
    close_active = nil
    pcall(vim.api.nvim_del_autocmd, autocmd_id)
    vim.o.guicursor = saved_guicursor
    backdrop.close(backdrop_handle)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  close_active = close

  autocmd_id = vim.api.nvim_create_autocmd({ "CursorMoved", "BufLeave", "InsertEnter" }, {
    once = true,
    callback = close,
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

M.show_cwd = function()
  show_float((vim.fn.getcwd():gsub("\\", "/")))
end

M.show_fullpath = function()
  show_float(buffer_path())
end

return M
