local M = {}

M.show_fullpath = function()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    path = "[No Name]"
  else
    path = path:gsub("\\", "/")
  end

  local max_width = math.floor(vim.o.columns * 0.6)
  local width = math.min(#path + 2, max_width)
  local height = math.max(1, math.ceil(#path / width))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { path })

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

return M
