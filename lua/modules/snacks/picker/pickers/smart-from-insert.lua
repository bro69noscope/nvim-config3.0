local M = {}

---Smart picker from insert mode. Hide the blink.cmp menu first.
M.open = function()
  local has_blink_cmp, blink_cmp = pcall(require, "blink.cmp")
  if has_blink_cmp and blink_cmp.is_visible() then
    blink_cmp.hide()
  end
  Snacks.picker.smart()
end

return M
