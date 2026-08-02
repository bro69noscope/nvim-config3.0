return {
  "https://git.sr.ht/~marcc/BufferBrowser",
  config = function()
    require("buffer_browser").setup({
      filetype_filters = { "gitcommit", "TelescopePrompt" },
    })

    local repeat_reverse = require("modules.buffer-browser.repeat-reverse")
    local next_buf, prev_buf = repeat_reverse.setup_buffer_browser()

    vim.keymap.set("n", "]b", next_buf, { desc = "Next [B]uffer" })
    vim.keymap.set("n", "[b", prev_buf, { desc = "Previous [B]uffer" })
  end,
}
