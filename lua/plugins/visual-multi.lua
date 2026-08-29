return {
  "mg979/vim-visual-multi",
  enabled = true,
  keys = {
    { "<C-Right>", desc = "Add cursor at position" },
    { "<C-Left>", desc = "Toggle cursor mappings" },
    { "<C-Up>", desc = "Add cursor up" },
    { "<C-Down>", desc = "Add cursor down" },
    { "<C-n>", mode = { "n", "v" }, desc = "Select next word" },
  },
  config = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "visual_multi_start",
      callback = function()
        local ok, autopairs = pcall(require, "nvim-autopairs")
        if ok then
          autopairs.disable()
        end
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      pattern = "visual_multi_exit",
      callback = function()
        local ok, autopairs = pcall(require, "nvim-autopairs")
        if ok then
          autopairs.force_attach()
          autopairs.enable()
        end
      end,
    })

    vim.g.VM_maps = {
      -- Fix conflict with treesitter-textobjects bindings
      ["Goto Next"] = "]v",
      ["Goto Prev"] = "[v",
      -- noop this shit else it will override the mappings
      ["I Return"] = "",
      ["I BS"] = "",
    }

    local incsearch_hl = vim.api.nvim_get_hl(0, { name = "IncSearch" })
    vim.api.nvim_set_hl(0, "VMCustom", {
      fg = incsearch_hl.fg, -- black fg text from IncSearch
      bg = "#ff59f4", -- bright pink background that contrasts well with IncSearch's orange
    })
    vim.api.nvim_set_hl(0, "VM_Extend", { link = "VMCustom" })
    vim.api.nvim_set_hl(0, "VM_Insert", { link = "VMCustom" })
    vim.api.nvim_set_hl(0, "VM_Cursor", { link = "VMCustom" })
    vim.api.nvim_set_hl(0, "VM_Mono", { link = "VMCustom" })

    vim.keymap.set(
      "n",
      "<C-Right>",
      "<Plug>(VM-Add-Cursor-At-Pos)",
      { noremap = true, silent = true }
    )
    vim.keymap.set("n", "<C-Left>", "<Plug>(VM-Toggle-Mappings)", { noremap = true, silent = true })
    vim.keymap.set("n", "<C-Up>", "<Plug>(VM-Add-Cursor-Up)", { noremap = true, silent = true })
    vim.keymap.set("n", "<C-Down>", "<Plug>(VM-Add-Cursor-Down)", { noremap = true, silent = true })
  end,
}
