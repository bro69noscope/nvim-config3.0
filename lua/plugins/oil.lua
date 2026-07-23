return {
  "stevearc/oil.nvim",
  enabled = true,
  -- Optional dependencies
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    float = {
      max_width = 0.9,
      max_height = 0.9,
    },
  },
  lazy = false,
  keys = {
    {
      "<leader>F",
      function()
        require("oil").open_float()
      end,
      desc = "Open Oil",
    },
  },
}
