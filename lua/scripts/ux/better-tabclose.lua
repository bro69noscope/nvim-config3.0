-- Return to previous tab when closing the current tab
vim.api.nvim_create_autocmd("TabEnter", {
  callback = function()
    vim.g.lasttab = vim.fn.tabpagenr("#")
  end,
})

vim.api.nvim_create_user_command("TabcloseBetter", function(opts)
  local previous_tab = vim.g.lasttab or 1
  vim.cmd("tabclose" .. (opts.bang and "!" or ""))
  if previous_tab <= vim.fn.tabpagenr("$") then
    vim.cmd("tabnext " .. previous_tab)
  end
end, { bang = true })
