local M = {}

---LSP references, including the reference under the cursor.
M.open = function()
  Snacks.picker.lsp_references({ include_current = true })
end

return M
