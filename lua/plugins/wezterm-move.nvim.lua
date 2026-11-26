return {
  "bro69noscope/wezterm-move.nvim",
  -- Better fitted for Windows. Hangs on neovide when at the edge.
  enabled = true and OnWindows and not OnNeovide,
  lazy = false, -- the plugin must set the WezTerm user var at startup
  opts = { log = true },
  keys = {
    { "<leader>olw", "<cmd>WeztermMoveLog<cr>", desc = "Open wezterm-move log" },
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
