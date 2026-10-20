return {
  "folke/persistence.nvim",
  enabled = true,
  lazy = false,
  event = "BufReadPre",
  opts = {},
  -- stylua: ignore
  keys = {
    { "<leader>qr", function() require("persistence").load() end,
    desc = "Restore Session", mode = { "n", "v" } },

    { "<leader>q`", function() require("persistence").select() end,
    desc = "Select Session", mode = { "n", "v" } },

    { "<leader>ql", function() require("persistence").load({ last = true }) end,
    desc = "Restore Last Session", mode = { "n", "v" } },

    { "<leader>qd", function() require("persistence").stop() end,
    desc = "Don't Save Current Session", mode = { "n", "v" } },

    { "<leader>qs", function() require("persistence").save() end,
    desc = "Save Session", mode = { "n", "v" } },
  },
}
