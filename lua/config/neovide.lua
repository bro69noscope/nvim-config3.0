if vim.g.neovide == true then
  vim.o.guifont = "BerkeleyMono Nerd Font"
  -- local zoomed_scale = 1.225

  -- this gives 150 cols with 1440p, 175% OS scale
  -- local zoomed_scale = 0.87

  -- this gives 150 cols with 1080p, 150% OS scale
  local zoomed_scale = 0.76

  local function paste()
    vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
  end
  vim.g.neovide_fullscreen = true
  vim.g.neovide_scale_factor = zoomed_scale
  vim.keymap.set("n", "<F11>", ":let g:neovide_fullscreen = !g:neovide_fullscreen<CR>", {})
  vim.keymap.set({ "n", "i", "v", "c", "t" }, "<C-S-v>", paste, { silent = true, desc = "Paste" })

  -- unbind weird inexplicable bugged keybinds
  vim.keymap.set("n", "<C-S-j>", "<Nop>")
  vim.keymap.set("n", "<C-S-k>", "<Nop>") -- this one doesn't bug, just for consistency

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

  vim.keymap.set("n", "<C-0>", function()
    vim.g.neovide_scale_factor = zoomed_scale
  end, { silent = true, desc = "Reset zoom" })
  return true
end
return false
