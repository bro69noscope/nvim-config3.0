if vim.g.neovide == true then
  vim.o.guifont = "BerkeleyMono Nerd Font"
  local zoomed_scale = 1.225
  local function paste()
    vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
  end
  vim.g.neovide_fullscreen = true
  vim.g.neovide_scale_factor = zoomed_scale
  vim.keymap.set("n", "<F11>", ":let g:neovide_fullscreen = !g:neovide_fullscreen<CR>", {})
  vim.keymap.set({ "n", "i", "v", "c", "t" }, "<C-S-v>", paste, { silent = true, desc = "Paste" })
  vim.keymap.set(
    "n",
    "<C-=>",
    ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>",
    { silent = true }
  )
  vim.keymap.set(
    "n",
    "<C-->",
    ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>",
    { silent = true }
  )
  vim.keymap.set("n", "<C-0>", ":lua vim.g.neovide_scale_factor = 1<CR>", { silent = true })
  vim.keymap.set(
    "n",
    "<C-/>",
    ":lua vim.g.neovide_scale_factor = " .. zoomed_scale .. "<CR>",
    { silent = true }
  )
  return true
end
return false
