return {
  "kwkarlwang/bufresize.nvim",
  enabled = true,
  init = function()
    _G.Bufresize = require("bufresize")
  end,
  opts = { noremap = true, silent = true },
  config = function()
    require("bufresize").setup({
      register = {
        keys = {
          --     { "n", "<c-w><", "<c-w><", opts },
          --     { "n", "<c-w>>", "<c-w>>", opts },
          --     { "n", "<c-w>+", "<c-w>+", opts },
          --     { "n", "<c-w>-", "<c-w>-", opts },
          --     { "n", "<c-w>_", "<c-w>_", opts },
          --     { "n", "<c-w>=", "<c-w>=", opts },
          --     { "n", "<c-w>|", "<c-w>|", opts },
          --     { "", "<LeftRelease>", "<LeftRelease>", opts },
          --     { "i", "<LeftRelease>", "<LeftRelease><c-o>", opts },
        },
        trigger_events = {
          -- "BufWinEnter",
          -- "WinEnter",
        },
      },
      resize = {
        keys = {},
        trigger_events = {
          -- "VimResized",
        },
        increment = false,
      },
    })
    ------------------------------------------------------------------------------------------------
  end,
  vim.keymap.set("n", "<leader>=ro", function()
    Bufresize.resize_open()
  end, { desc = "resize_open" }),

  vim.keymap.set("n", "<leader>=rc", function()
    Bufresize.resize_close()
  end, { desc = "resize_close" }),

  vim.keymap.set("n", "<leader>=rb", function()
    Bufresize.block_register()
  end, { desc = "block_register" }),

  vim.keymap.set("n", "<leader>=rr", function()
    Bufresize.register()
  end, { desc = "register" }),
}
