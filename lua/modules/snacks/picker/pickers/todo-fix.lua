local M = {}

---Todo comments limited to TODO, FIX and FIXME.
M.open = function()
  Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
end

return M
