local M = {}

---Grep the visual selection or the word under the cursor, as a literal string.
M.open = function()
  Snacks.picker.grep_word({
    title = "Grep word",
    _root_title = "Grep word",
    regex = false,
    args = {},
    show_empty = true,
  })
end

return M
