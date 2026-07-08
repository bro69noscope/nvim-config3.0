local M = {}

M.quickfix_toggle = Snacks.toggle.new({
  name = "Quickfix",
  notify = false,
  get = function()
    for _, win in ipairs(vim.fn.getwininfo()) do
      if win.quickfix == 1 then
        return true
      end
    end
    return false
  end,
  set = function(enabled)
    if enabled then
      vim.cmd.copen()
    else
      vim.cmd.cclose()
    end
  end,
})

return M
