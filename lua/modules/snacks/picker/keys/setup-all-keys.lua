local M = {}
---@param dirs? table<string>
---@param title? string
---@param source? string
M.setup_grep_input_keys = function(dirs, title, source)
  return {
    ["<F1>"] = { "grep_globs_input", mode = { "n", "i" }, desc = "Filter by file pattern(s)" },
    ["<F2>"] = { "toggle_and_search", mode = { "i", "n" } },
    ["<F3>"] = { "toggle_smartcase", mode = { "i", "n" } },
  }
end
return M
