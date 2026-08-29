local M = {}

local restore_wezmove_bindings = function(wezmove)
  vim.keymap.set("n", DownWindowBind, function()
    wezmove.move("j")
  end)

  vim.keymap.set("n", UpWindowBind, function()
    wezmove.move("k")
  end)
end

local restore_smart_splits_bindings = function(smartsplits)
  vim.keymap.set("n", DownWindowBind, function()
    smartsplits.move_cursor_down()
  end)

  vim.keymap.set("n", UpWindowBind, function()
    smartsplits.move_cursor_up()
  end)
end

function M.restore_gs_bindings()
  vim.keymap.set("n", "q", "", { noremap = true, desc = "Quit most things" })
  vim.keymap.set("n", "Q", "q", { noremap = true, desc = "Record macro" })
  local has_wezmove, wezmove = pcall(require, "wezterm-move")
  if has_wezmove then
    restore_wezmove_bindings(wezmove)
  end
  local has_smartsplits, smartsplits = pcall(require, "smart-splits")
  if has_smartsplits then
    restore_smart_splits_bindings(smartsplits)
  end
end

return M
