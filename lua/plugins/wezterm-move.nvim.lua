return {
  -- "letieu/wezterm-move.nvim",
  "woertsposzibllen4me/wezterm-move.nvim", -- forked for custom functionality
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
        -- Check if we landed in neo-tree and auto-move right
        if vim.bo.filetype == "neo-tree" then
          require("wezterm-move").move("l")
        end
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
