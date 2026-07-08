local M = {}
M.diagnostic_underlines_toggle = Snacks.toggle.new({
  name = "Diagnostic underlines",
  get = function()
    local config = vim.diagnostic.config()
    if config then
      return config.underline ~= false
    else
      return false
    end
  end,
  set = function(state)
    vim.diagnostic.config({ underline = state })
  end,
})
return M
