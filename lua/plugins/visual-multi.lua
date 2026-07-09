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
    -- Hack around issue with conflicting insert mode <BS> mapping
    -- between this plugin and nvim-autopairs
    vim.api.nvim_create_autocmd("User", {
      pattern = "visual_multi_start",
      callback = function()
        pcall(vim.keymap.del, "i", "<BS>", { buffer = 0 })
        -- require("nvim-autopairs").force_detach()
        require("nvim-autopairs").disable()

        vim.keymap.set("i", "<Up>", function()
          vim.notify("test")
          if require("blink.cmp").is_visible() then
            require("blink.cmp").select_prev()
            vim.notify("Selected previous completion item", vim.log.levels.INFO, {
              title = "Blink CMP",
            })
          else
            return "<Up>"
          end
        end, { expr = true, buffer = true })

        vim.keymap.set("i", "<Down>", function()
          vim.notify("test")
          if require("blink.cmp").is_visible() then
            require("blink.cmp").select_next()
            vim.notify("Selected next completion item", vim.log.levels.INFO, {
              title = "Blink CMP",
            })
          else
            return "<Down>"
          end
        end, { expr = true, buffer = true })
      end,
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "visual_multi_exit",
      callback = function()
        require("nvim-autopairs").force_attach()
        require("nvim-autopairs").enable()
        pcall(vim.keymap.del, "i", "<Up>", { buffer = true })
        pcall(vim.keymap.del, "i", "<Down>", { buffer = true })
      end,
    })

    -- Fixes conflict with treesitter-textobjects bindings
    vim.g.VM_maps = {
      ["Goto Next"] = "]v",
      ["Goto Prev"] = "[v",
      -- Disable some mappings to allow blink.cmp navigation
      ["I Return"] = "<S-CR>",
      ["I Up"] = "",
      ["I Down"] = "",
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

    -- Dropoff cursor at current position
    vim.keymap.set(
      "n",
      "<C-Right>",
      "<Plug>(VM-Add-Cursor-At-Pos)",
      { noremap = true, silent = true }
    )
    -- Toggle cursors shifting with HJKL
    vim.keymap.set("n", "<C-Left>", "<Plug>(VM-Toggle-Mappings)", { noremap = true, silent = true })
    -- Add cursors up/down
    vim.keymap.set("n", "<C-Up>", "<Plug>(VM-Add-Cursor-Up)", { noremap = true, silent = true })
    vim.keymap.set("n", "<C-Down>", "<Plug>(VM-Add-Cursor-Down)", { noremap = true, silent = true })
  end,
}
