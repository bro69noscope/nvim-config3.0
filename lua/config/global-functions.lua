local smart_splits_moves = {
  h = "move_cursor_left",
  j = "move_cursor_down",
  k = "move_cursor_up",
  l = "move_cursor_right",
}

---@param dir string "h|j|k|l"
function _G.WindowMove(dir)
  return function()
    local name = (OnWindows and not OnNeovide) and "wezterm-move" or "smart-splits"
    local ok, plugin = pcall(require, name)

    if not ok then
      vim.notify_once(name .. " not available, fallback to wincmd", vim.log.levels.WARN)
      vim.cmd.wincmd(dir)
    elseif name == "wezterm-move" then
      plugin.move(dir)
    else
      plugin[smart_splits_moves[dir]]()
    end
  end
end
