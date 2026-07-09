return {
  "folke/trouble.nvim",
  enabled = true,
  cmd = { "Trouble" },
  opts = {
    focus = true,
    max_items = 400,
    modes = {
      lsp = {
        win = { position = "right" },
      },
    },
  },
  config = function(_, opts)
    require("trouble").setup(opts)
    -- Navigate trouble only
    vim.keymap.set("n", "<Left>", function()
      if require("trouble").is_open() then
        ---@ diagnostic disable-next-line: missing-fields, missing-parameter
        require("trouble").prev({ skip_groups = true, jump = true })
      end
    end, { desc = "Previous Trouble Item" })

    vim.keymap.set("n", "<Right>", function()
      if require("trouble").is_open() then
        ---@ diagnostic disable-next-line: missing-fields, missing-parameter
        require("trouble").next({ skip_groups = true, jump = true })
      end
    end, { desc = "Next Trouble Item" })

    vim.keymap.set("n", "<leader>wx", function()
      if require("trouble").is_open() then
        ---@ diagnostic disable-next-line: missing-parameter
        require("trouble").focus()
      end
    end, { desc = "Focus Trouble Window" })
  end,
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
    {
      "<leader>xb",
      "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
      desc = "Buffer Diagnostics (Trouble)",
    },
    { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
    { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
  },
}
