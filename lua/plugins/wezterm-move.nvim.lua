return {
  -- "letieu/wezterm-move.nvim",
  "woertsposzibllen4me/wezterm-move.nvim",
  enabled = OnWindows and true and not OnNeovide, -- Better fitted for Windows.  NOTE: forked for custom functionality
  keys = {
    {
      "<C-h>",
      function()
        require("wezterm-move").move("h")
      end,
    },
    {
      "<C-j>",
      function()
        require("wezterm-move").move("j")
      end,
    },
    {
      "<C-k>",
      function()
        require("wezterm-move").move("k")
        -- Check if we landed in neo-tree and auto-move right
        if vim.bo.filetype == "neo-tree" then
          require("wezterm-move").move("l")
        end
      end,
    },
    {
      "<C-l>",
      function()
        require("wezterm-move").move("l")
      end,
    },
  },
}
