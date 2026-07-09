-- Module to setup Snacks toggles keymaps
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
    Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
    Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
    Snacks.toggle.diagnostics():map("<leader>xt")
    Snacks.toggle
      .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
      :map("<leader>uC")
    Snacks.toggle.treesitter():map("<leader>uT")
    Snacks.toggle.inlay_hints():map("<leader>uh")

    -- Custom toggles
    local ctt = require("modules.snacks.toggle.custom-toggles.color_column").colorcolumn_toggle
    ctt:map("<leader>uc")

    local vtt = require("modules.snacks.toggle.custom-toggles.virtual-text").virtual_text_toggle
    vtt:map("<leader>xl")

    local wdtgl = require("modules.snacks.toggle.custom-toggles.word-diff-hl").word_diff_toggle
    wdtgl:map("<leader>uW")

    local jpt =
      require("modules.snacks.toggle.custom-toggles.jsonpath-statusline").jsonpath_statusline_toggle
    jpt:map("<leader>uj")

    local udlt =
      require("modules.snacks.toggle.custom-toggles.diag-underlines").diagnostic_underlines_toggle
    udlt:map("<leader>xu")

    local qft = require("modules.snacks.toggle.custom-toggles.quickfix-win").quickfix_toggle
    qft:map("<leader>C")
  end,
})
