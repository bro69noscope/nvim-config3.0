local M = {}
M.patched_jumps_finder = function()
  -- NOTE: ai code to review, seems to work. Fixes crash on invalid buffer preview.
  -- TODO: create issue
  local jumps = vim.fn.getjumplist()[1]
  local items = {}
  for _, jump in ipairs(jumps) do
    local buf_valid = jump.bufnr and jump.bufnr > 0 and vim.api.nvim_buf_is_valid(jump.bufnr)
    local buf = buf_valid and jump.bufnr or nil
    local file = jump.filename
    if not file and buf then
      file = vim.api.nvim_buf_get_name(buf)
    end

    -- skip entries with no usable buffer AND no file that still exists on disk
    local file_exists = file and file ~= "" and vim.uv.fs_stat(file) ~= nil
    if buf or file_exists then
      local line
      if buf then
        line = vim.api.nvim_buf_get_lines(buf, jump.lnum - 1, jump.lnum, false)[1]
      end
      local label = tostring(#jumps - #items)
      table.insert(items, 1, {
        label = Snacks.picker.util.align(label, #tostring(#jumps), { align = "right" }),
        buf = buf,
        line = line,
        text = table.concat({ file, line }, " "),
        file = file,
        pos = jump.lnum and jump.lnum > 0 and { jump.lnum, jump.col } or nil,
      })
    end
  end
  return items
end
return M
