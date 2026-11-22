-- Return to previous tab when closing the current tab
vim.api.nvim_create_autocmd("TabEnter", {
  callback = function()
    vim.g.lasttab = vim.fn.tabpagenr("#")
  end,
})

vim.api.nvim_create_user_command("TabcloseBetter", function(opts)
  local previous_tab = vim.g.lasttab or 1

  if vim.fn.tabpagenr("$") == 1 then
    vim.notify("Cannot close last tab page", vim.log.levels.WARN)
    return
  end

  -- Stop diff mode before the tab closes. Else, `tabclose` wipes the gitsigns diff buffer, which
  -- triggers DiffUpdated while the windows close. lua/plugins/render-markdown.lua then reads a
  -- closing window, and nvim crashes (nvim 0.12.6). TODO: PRIO9 create issue?
  vim.cmd("diffoff!")

  vim.cmd("tabclose" .. (opts.bang and "!" or ""))
  if previous_tab <= vim.fn.tabpagenr("$") then
    vim.cmd("tabnext " .. previous_tab)
  end
end, { bang = true })
