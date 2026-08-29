return {
  {
    "mrjones2014/smart-splits.nvim",
    enabled = false and not OnWindows or OnNeovide, -- We don't use it on Windows (a bit slow, for
    -- wezterm at least, we have an alternative plugin). We do use it on Neovide due to the absence
    -- of wezterm tabs here.
    lazy = false,
    opts = {
      at_edge = "stop",
    },
    keys = {
      {
        "<C-h>",
        function()
          require("smart-splits").move_cursor_left()
        end,
        desc = "Move to left split",
      },
      {
        "<C-j>",
        function()
          require("smart-splits").move_cursor_down()
        end,
        desc = "Move to bottom split",
      },
      {
        "<C-k>",
        function()
          require("smart-splits").move_cursor_up()
        end,
        desc = "Move to top split",
      },
      {
        "<C-l>",
        function()
          require("smart-splits").move_cursor_right()
        end,
        desc = "Move to right split",
      },
      -- {
      --   "<M-Left>",
      --   function()
      --     require("smart-splits").resize_left()
      --   end,
      --   desc = "Resize left split",
      -- },
      -- {
      --   "<M-Down>",
      --   function()
      --     require("smart-splits").resize_down()
      --   end,
      --   desc = "Resize bottom split",
      -- },
      -- {
      --   "<M-Up>",
      --   function()
      --     require("smart-splits").resize_up()
      --   end,
      --   desc = "Resize top split",
      -- },
      -- {
      --   "<M-Right>",
      --   function()
      --     require("smart-splits").resize_right()
      --   end,
      --   desc = "Resize right split",
      -- },
    },
  },
}
