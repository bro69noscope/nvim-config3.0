-- pieced with: windows\autohotkey\utils-script\nvim-scratch\scratch.ahk
local map = require("scripts.ui.whichkey-map").map

local scratch_dir = vim.fn.expand("$TEMP"):gsub("\\", "/") .. "/nvim-scratch"
local scratch_pattern = scratch_dir .. "/scratch_*"
local done_flag = scratch_dir .. "/done.flag"
local req_file = scratch_dir .. "/request.txt"

vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = scratch_pattern,
  callback = function(_)
    local clip = vim.fn.getreg("+")
    if clip ~= "" then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(clip, "\n"))
    end
  end,
})

local launched_as_scratch = vim.g.nvim_scratch == 1

local function setup_tabs()
  if launched_as_scratch then
    vim.t.custom_tabname = "dontclose"
    -- fresh buffer to replace whatever a dashboard plugin could have opened at startup
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(
      buf,
      0,
      -1,
      false,
      { "this tab is kept open to be able to reuse this nvim instance" }
    )
    vim.api.nvim_win_set_buf(0, buf)
  end
end

if launched_as_scratch then
  map("n", "<localleader>x", function()
    if vim.t.custom_tabname == "dontclose" then
      vim.notify("refusing to close the dontclose tab", vim.log.levels.WARN)
      return
    end
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    vim.fn.setreg("+", table.concat(lines, "\n"))
    vim.cmd("tabclose!")
    vim.fn.writefile({}, done_flag)
  end, { desc = "Close scratch tab, copy its content to clipboard, signal AHK", icon = "💃" })

  local watcher = vim.uv.new_timer()
  watcher:start(
    0,
    50,
    vim.schedule_wrap(function()
      if vim.fn.filereadable(req_file) == 0 then
        return
      end
      local file = vim.fn.readfile(req_file)[1]
      vim.fn.delete(req_file)
      vim.cmd("tabnew " .. vim.fn.fnameescape(file))
      vim.t.custom_tabname = "scratch"
    end)
  )
end

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy", -- dont even fkn think about using VimEnter here.
  once = true,
  callback = function()
    vim.schedule(setup_tabs)
  end,
})
