local M = {}

-- Close all diffview panels, then open the file at the cursor position we were at
M.close_and_jump = function()
  local actions = require("diffview.actions")
  local path, cursor

  -- focus the diff window showing a real file (not a diffview:// buffer)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.wo[win].diff then
      local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
      if name ~= "" and not name:match("^diffview://") then
        vim.api.nvim_set_current_win(win)
        path = name
        cursor = vim.api.nvim_win_get_cursor(win)
        break
      end
    end
  end

  actions.close()

  if path and path ~= "" then
    vim.schedule(function()
      if vim.fn.filereadable(path) == 1 then
        if vim.fs.normalize(vim.api.nvim_buf_get_name(0)) ~= vim.fs.normalize(path) then
          vim.cmd("edit " .. vim.fn.fnameescape(path))
        end
        if cursor then
          pcall(vim.api.nvim_win_set_cursor, 0, cursor)
          vim.cmd("normal! zz")
        end
      end
    end)
  end
end

return M
