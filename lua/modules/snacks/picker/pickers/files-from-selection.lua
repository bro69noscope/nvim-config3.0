local M = {}

---Find files, with the visual selection as the search pattern.
M.open = function()
  Snacks.picker.files({ pattern = Snacks.picker.util.visual().text })
end

return M
