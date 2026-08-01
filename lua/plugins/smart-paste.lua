return {
  "nemanjamalesija/smart-paste.nvim",
  event = "VeryLazy",
  config = function()
    vim.keymap.set("n", "<M-p>", function()
      require("smart-paste").paste({ register = "+", key = "p" })
    end, { desc = "Smart paste from system clipboard" })
  end,
}
