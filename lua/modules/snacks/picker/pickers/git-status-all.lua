local M = {}

---Git status including submodules files. The source is in sources/git-status-all.lua.
M.open = function()
  Snacks.picker.git_status_all()
end

return M
