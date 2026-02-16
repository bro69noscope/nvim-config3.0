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

    -- Colorcolumn toggle
    local function cc_for_current()
      local ft = vim.bo.filetype
      local lenght = Linelenght_by_ft[ft] or 80
      return tostring(lenght)
    end

    Snacks.toggle.option("colorcolumn", { off = "", on = cc_for_current }):map("<leader>uc")

    -- Custom toggles
    local ctt = require("modules.snacks.toggle.custom-toggles.color_column").colorcolumn_toggle
    ctt:map("<leader>uc")

    local vtt = require("modules.snacks.toggle.custom-toggles.virtual-text").virtual_text_toggle
    vtt:map("<leader>xl")

    local wdtgl = require("modules.snacks.toggle.custom-toggles.word-diff-hl").word_diff_toggle
    wdtgl:map("<leader>gw")
  end,
})
