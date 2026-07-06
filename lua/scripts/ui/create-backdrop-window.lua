local M = {}

vim.api.nvim_set_hl(0, "Backdrop", { bg = "#000000", default = true })

--- Opens a full-screen dimming backdrop window.
--- @param opts table|nil { blend = number, zindex = number}
--- @return table handle - pass this to M.close()
function M.open(opts)
  opts = opts or {}
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = 0,
    col = 0,
    width = vim.o.columns,
    height = vim.o.lines,
    style = "minimal",
    focusable = false,
    zindex = opts.zindex or 40,
  })
  vim.wo[win].winhighlight = "Normal:Backdrop"
  vim.wo[win].winblend = opts.blend or 30

  return { buf = buf, win = win }
end

--- Closes a backdrop previously returned by M.open()
--- @param handle table
function M.close(handle)
  if handle and handle.win and vim.api.nvim_win_is_valid(handle.win) then
    vim.api.nvim_win_close(handle.win, true)
  end
end

--- Convenience: auto-close the backdrop when a given window closes.
--- @param target_win number the floating window to watch
--- @param handle table the backdrop handle to close
function M.link_to_window(target_win, handle)
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(target_win),
    once = true,
    callback = function()
      M.close(handle)
    end,
  })
end

return M
