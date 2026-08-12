local M = {}
M.capture_current_buffer_info = function(opts)
  opts = opts or {}
  local silent = opts.silent or false
  local bufname = vim.fn.bufname("%")
  local raw_bufname = vim.inspect(bufname)
  local title = vim.o.titlestring
  local filetype = vim.bo.filetype
  local buftype = vim.bo.buftype
  local absolute_path = vim.fn.expand("%:p")
  local buf_vars = vim.b -- Buffer variables
  local win_config = vim.api.nvim_win_get_config(0)

  if not silent then
    print("=== Buffer Info ===")
    print("Current buffer name: " .. bufname)
    print("Raw buffer name: " .. raw_bufname)
    print("Current titlestring: " .. title)
    print("Current buffer type: " .. filetype)
    print("Current buffer type (buftype): " .. buftype)
    print("Absolute path: " .. absolute_path)
    print("Buffer variables: " .. vim.inspect(buf_vars))
    print("Window configuration: " .. vim.inspect(win_config))
  end

  return { bufname = bufname, raw_bufname = raw_bufname, title = title }
end

M.list_treesitter_installed_parsers = function()
  local parsers = require("nvim-treesitter").get_installed("parsers")
  print("Installed Treesitter parsers: " .. vim.inspect(parsers))
end

return M
