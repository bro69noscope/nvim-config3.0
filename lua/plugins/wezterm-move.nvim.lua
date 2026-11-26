return {
  -- "letieu/wezterm-move.nvim",
  "bro69noscope/wezterm-move.nvim", -- forked for custom functionality
  enabled = true and OnWindows and not OnNeovide, -- Better fitted for Windows. Hangs on neovide when
  -- at the edge.
  keys = {
    {
      LeftWindowBind,
      function()
        require("wezterm-move").move("h")
      end,
    },
    {
      DownWindowBind,
      function()
        require("wezterm-move").move("j")
      end,
    },
    {
      UpWindowBind,
      function()
        require("wezterm-move").move("k")
      end,
    },
    {
      RightWindowBind,
      function()
        require("wezterm-move").move("l")
      end,
    },
  },
}
