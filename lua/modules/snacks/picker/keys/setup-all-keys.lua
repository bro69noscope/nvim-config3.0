local M = {}

---@param dirs? table<string> the particular directories the grep might be happening in
---@param title? string the currently set, non-default, title of the picker
M.setup_grep_input_keys = function(dirs, title)
  local grep_globs_input = require("modules.snacks.picker.keys.input-grep-globs")
  return {
    ["<F1>"] = grep_globs_input.setup_grep_globs_input(dirs, title),
    ["<F2>"] = { "toggle_and_search", mode = { "i", "n" } },
    ["<F3>"] = { "toggle_smartcase", mode = { "i", "n" } },
  }
end

return M
