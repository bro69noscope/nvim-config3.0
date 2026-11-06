local diff_sanitize = require("scripts.ui.diff-sanitize")
local autocmds = require("modules.diffview.autocmds")

local M = {}

--- @ diagnostic disable-next-line: unused-local
M.view_opened = function(view)
  autocmds.save_wrap_state()
  diff_sanitize.disable_diff_features()

  -- Name tabpage with diffview info
  vim.schedule(function()
    local tabpage = vim.api.nvim_get_current_tabpage()
    vim.api.nvim_create_autocmd("User", {
      pattern = "DiffviewDiffBufWinEnter",
      callback = function()
        if vim.api.nvim_get_current_tabpage() == tabpage then
          local filename = vim.fn.expand("%:t")
          if filename ~= "" and filename ~= "null" then
            vim.t.custom_tabname = "diffview: " .. filename
          end
        end
      end,
    })
  end)
end

M.view_closed = function()
  diff_sanitize.re_enable_diff_features()
end

--- @ diagnostic disable-next-line: unused-local
M.diff_buf_read = function(bufnr)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    vim.wo[win].winbar = ""
    vim.wo[win].culopt = "number"
    vim.wo[win].wrap = false
  end
end

--- @ diagnostic disable-next-line: unused-local
M.diff_buf_win_enter = function(bufnr, winid, ctx)
  if ctx.layout_name:match("^diff2") then
    if ctx.symbol == "a" then
      vim.opt_local.winhl = table.concat({
        "DiffAdd:DiffviewDiffAddAsDelete",
        "DiffDelete:DiffviewDiffDelete",
      }, ",")
    elseif ctx.symbol == "b" then
      vim.opt_local.winhl = table.concat({
        "DiffDelete:DiffviewDiffDelete",
      }, ",")
    end
  end
end

return M
