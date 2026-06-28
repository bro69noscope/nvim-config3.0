-- better yank/paste
return {
  "gbprod/yanky.nvim",
  enabled = true,
  lazy = true,
  event = "VeryLazy",
  recommended = true,
  desc = "Better Yank/Paste",
  opts = {
    highlight = { timer = 150 },
  },
  keys = {
    {
      "<leader>P",
      function()
        require("telescope").extensions.yank_history.yank_history({})
      end,
      mode = { "n", "x" },
      desc = "Open Yank History",
    },
    {
      "<c-o>",
      function()
        require("telescope").extensions.yank_history.yank_history({})
      end,
      mode = { "i" },
      desc = "Open Yank History",
    },
    {
      "<c-p>",
      function()
        require("telescope").extensions.yank_history.yank_history({})
      end,
      mode = { "i" },
      desc = "Open Yank History",
    },
        -- stylua: ignore
    { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank Text" },
    { "Y", "<Plug>(YankyYank)$", mode = { "n", "x" }, desc = "Yank Text to End of Line" },
    { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put Text After Cursor" },
    { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put Text Before Cursor" },
    { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put Text After Selection" },
    { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put Text Before Selection" },
    { "[y", "<Plug>(YankyCycleForward)", desc = "Cycle Forward Through Yank History" },
    { "]y", "<Plug>(YankyCycleBackward)", desc = "Cycle Backward Through Yank History" },
  },
}
