local M = {}
M.qflist_append = function(picker)
  picker:close()
  local sel = picker:selected()
  local items = #sel > 0 and sel or picker:items()
  local qf = {} ---@type vim.quickfix.entry[]
  for _, item in ipairs(items) do
    qf[#qf + 1] = {
      filename = Snacks.picker.util.path(item),
      bufnr = item.buf,
      lnum = item.pos and item.pos[1] or 1,
      col = item.pos and item.pos[2] + 1 or 1,
      end_lnum = item.end_pos and item.end_pos[1] or nil,
      end_col = item.end_pos and item.end_pos[2] + 1 or nil,
      text = item.line or item.comment or item.label or item.name or item.detail or item.text,
      pattern = item.search,
      valid = true,
    }
  end
  vim.fn.setqflist(qf, "a")
  vim.cmd("botright copen")
end

return M
