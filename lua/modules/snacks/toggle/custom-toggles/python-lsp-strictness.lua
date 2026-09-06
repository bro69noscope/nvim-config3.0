local strictness = require("lang.python.lsp.change-lsp-strictness")

local M = {}

M.py_lsp_strictness_toggle = Snacks.toggle.new({
  name = "Python LSP Relaxed Mode",
  get = function()
    local toml_path = strictness.find_pyproject()
    if not toml_path then
      return false
    end
    return strictness.is_currently_normal(toml_path)
  end,
  set = function(state)
    strictness.set_lsp_strictness(state)
  end,
})

return M
