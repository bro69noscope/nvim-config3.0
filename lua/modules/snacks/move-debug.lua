local M = {}

local CTX = "snacks.move"

--- Wrap `explorer_move` so every move attempt (selection + target dir) is logged via the global
--- Logger. Per-file results are logged by `modules.snacks.rename-debug`, since the move calls
--- `_rename`.
function M.setup()
  local ok, explorer_actions = pcall(require, "snacks.explorer.actions")
  if not ok then
    Logger.warn("snacks.explorer.actions not found, move logging disabled", CTX)
    return
  end

  local orig = explorer_actions.actions.explorer_move
  explorer_actions.actions.explorer_move = function(picker, ...)
    local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected())
    if #paths == 0 then
      Logger.info("move invoked with empty selection, falls back to rename", CTX)
    else
      Logger.info(
        ("move attempt target=%q count=%d files=%s"):format(
          picker:dir(),
          #paths,
          vim.inspect(paths)
        ),
        CTX
      )
    end
    return orig(picker, ...)
  end
end

return M
