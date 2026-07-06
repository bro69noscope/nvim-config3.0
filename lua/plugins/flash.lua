return {
  "folke/flash.nvim",
  enabled = true,
  event = "VeryLazy", -- Needs to be loaded soon for jump labels to work when doing "nvim file" in terminal
  lazy = true,
  priority = 49, -- Needs to load after treesitter text objects to correctly override the "f" and "t" keys
  vscode = true,
  opts = {
    labels = "atinehcsbwrodypulmgfvjkxqz", -- enthium layout
    -- labels = "atinehcsbwrodypulmgfvjkxqz", -- enthium layout
    modes = {
      char = {
        jump_labels = true,
        label = { exclude = "hjkliardcx" },
      },
    },
  },
  keys = {
    {
      "s",
      mode = { "n", "x", "o" },
      function()
        require("flash").jump()
      end,
      desc = "Flash",
    },
    {
      "S",
      mode = { "n", "o", "x" },
      function()
        require("flash").treesitter()
      end,
      desc = "Flash Treesitter",
    },
    {
      "r",
      mode = "o",
      function()
        require("flash").remote()
      end,
      desc = "Remote Flash",
    },
    {
      "R",
      mode = { "o", "x" },
      function()
        require("flash").treesitter_search()
      end,
      desc = "Treesitter Search",
    },
  },
}
