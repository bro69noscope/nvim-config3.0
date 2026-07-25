return {
  "https://git.sr.ht/~marcc/BufferBrowser",
  config = function()
    require("buffer_browser").setup({
      filetype_filters = { "gitcommit", "TelescopePrompt" },
    })

    vim.keymap.set(
      "n",
      "<leader>b]",
      require("buffer_browser").next,
      { desc = "Next [B]uffer []]" }
    )
    vim.keymap.set(
      "n",
      "<leader>b[",
      require("buffer_browser").prev,
      { desc = "Previous [B]uffer [[]" }
    )
  end,
}
