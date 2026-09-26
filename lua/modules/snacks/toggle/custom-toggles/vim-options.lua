local M = {}

M.smartindent_toggle = Snacks.toggle.new({
  name = "Smart Indent",
  get = function()
    return vim.bo.smartindent
  end,
  set = function(state)
    vim.bo.smartindent = state
  end,
})

M.expandtab_toggle = Snacks.toggle.new({
  name = "Expand Tab",
  get = function()
    return vim.bo.expandtab
  end,
  set = function(state)
    vim.bo.expandtab = state
  end,
})

return M
