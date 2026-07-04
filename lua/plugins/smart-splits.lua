return {
  {
    "mrjones2014/smart-splits.nvim",
    enabled = not OnWindows and true, -- We don't use it on Windows (a bit slow, we have an
    -- alternative plugin)
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
          if vim.bo.filetype == "snacks_picker_list" then
            local win_config = vim.api.nvim_win_get_config(0)
            if win_config.zindex == 33 then -- Snack explorer is on same zindex as main window
              vim.cmd("wincmd l")
              Logger.debug("triggered wincmd l in snack explorer list", "smart-splits")
            end
          else
            require("smart-splits").move_cursor_right()
          end
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
