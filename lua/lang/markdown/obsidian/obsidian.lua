local M = {}

local ahk_exe =
  require("lang.autohotkey.lsp.autohotkey-lsp-settings").ahk2.init_options.InterpreterPath

local focus_script =
  vim.fs.joinpath(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)), "focus-obsidian.ahk")

-- Open the current file in Obsidian. Then AHK activates the Obsidian window and clicks in it.
function M.open_current_file()
  local path = vim.fn.expand("%:p"):gsub("\\", "/")
  local _, err = vim.ui.open("obsidian://open?path=" .. vim.uri_encode(path, "rfc3986"))
  if err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  if vim.fn.executable(ahk_exe) == 0 then
    return
  end

  vim.system({ ahk_exe, "/ErrorStdOut", focus_script }, {}, function(res)
    if res.code ~= 0 then
      vim.schedule(function()
        vim.notify(
          ("focus-obsidian.ahk failed (exit %d): %s"):format(res.code, res.stderr),
          vim.log.levels.WARN
        )
      end)
    end
  end)
end

return M
