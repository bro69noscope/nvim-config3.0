local M = {}

local function cc_for_current()
  return tostring(Linelenght_by_ft[vim.bo.filetype] or 80)
end

M.colorcolumn_toggle = Snacks.toggle.new({
  name = "Color Column",
  get = function()
    return vim.wo.colorcolumn ~= ""
  end,
  set = function(state)
    if state then
      vim.wo.colorcolumn = cc_for_current()
    else
      vim.wo.colorcolumn = ""
    end
  end,
})

return M
