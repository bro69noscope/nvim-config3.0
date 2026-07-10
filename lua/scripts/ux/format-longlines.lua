local M = {}

M.makeshift_format = function()
  local tw = vim.bo.textwidth
  local ft = vim.bo.filetype

  if tw == 0 then
    vim.notify("textwidth not set for ft " .. ft, vim.log.levels.ERROR)
    return
  end

  for i = vim.fn.line("$"), 1, -1 do
    if #vim.fn.getline(i) > tw then
      vim.fn.cursor(i, 1)
      vim.cmd("normal! gww")
    end
  end
end

return M
