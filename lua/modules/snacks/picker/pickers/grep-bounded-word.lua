local M = {}

---Grep the visual selection or the word under the cursor, with word bounds.
M.open = function()
  local word
  if vim.fn.mode():match("[vV\22]") then
    vim.cmd('noau normal! "vy"')
    word = vim.fn.getreg("v")
  else
    word = vim.fn.expand("<cword>")
  end
  word = vim.fn.escape(word, "\\/.*$^~[]")

  Snacks.picker.grep_word({
    title = "Grep bounded word",
    _root_title = "Grep bounded word",
    regex = true,
    search = "\\b" .. word .. "\\b",
    args = {},
  })
end

return M
