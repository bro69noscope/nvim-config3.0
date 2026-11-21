local M = {}

---Default grepping (without the finder overriden by egrepify).
M.open = function()
  Snacks.picker.grep({ finder = "grep" })
end

return M
