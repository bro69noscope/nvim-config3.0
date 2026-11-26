return {
  -- "letieu/wezterm-move.nvim",
  -- forked: personal custom functionality. Works along `../wezterm/nvim/wezterm-move/wezmove.lua`
  "bro69noscope/wezterm-move.nvim",
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
