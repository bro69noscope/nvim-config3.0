vim.api.nvim_set_hl(0, "DiffWinSeparator", { fg = "#7aa2f7", bg = "NONE" })

local function diff_layout()
  local rows, cols = {}, {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.wo[win].diff then
      local pos = vim.api.nvim_win_get_position(win)
      rows[pos[1]] = true
      cols[pos[2]] = true
    end
  end
  if vim.tbl_count(cols) > 1 then
    return "vertical" -- side by side
  elseif vim.tbl_count(rows) > 1 then
    return "horizontal" -- stacked
  end
end

vim.api.nvim_create_autocmd({ "OptionSet" }, {
  callback = function()
    if not vim.wo.diff then
      return
    end

    local layout = diff_layout()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.wo[win].diff then
        vim.wo[win].winhighlight = layout == "horizontal" and "WinSeparator:DiffWinSeparator" or ""
      end
    end
  end,
})
