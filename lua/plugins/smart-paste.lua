return {
  "nemanjamalesija/smart-paste.nvim",
  event = "VeryLazy",
  config = function()
    vim.keymap.set({ "n", "v" }, "<m-p>", function()
      require("smart-paste").paste({ register = "+", key = "p" })
    end, { desc = "Smart paste from clipboard" })
    vim.keymap.set("i", "<m-p>", "<c-r>+", { desc = "Paste from system clipboard" })
  end,
}
