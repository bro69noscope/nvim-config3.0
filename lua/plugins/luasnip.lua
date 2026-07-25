return {
  "L3MON4D3/LuaSnip",
  enabled = true,
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  config = function()
    local ls = require("luasnip")

    -- -- example
    -- local s = ls.snippet
    -- local t = ls.text_node
    -- local i = ls.insert_node
    -- local f = ls.function_node
    -- local c = ls.choice_node
    --
    -- ls.add_snippets("all", {
    --   s("testsnip", {
    --     t("function "),
    --     i(1, "name"),
    --     t("("),
    --     i(2),
    --     t(") "),
    --     c(3, { -- This is a choice node
    --       t("returns this"),
    --       t("returns or_that"),
    --     }),
    --     t({ "", "  " }),
    --     i(0),
    --     t({ "", "end" }),
    --   }),
    -- })

    require("luasnip.loaders.from_vscode").lazy_load()

    -- Movement inside snippets slots
    vim.keymap.set({ "i", "s" }, "<m-j>", function()
      return ls.jumpable(1) and "<Plug>luasnip-jump-next" or "<Tab>"
    end, { expr = true, silent = true })

    vim.keymap.set({ "i", "s" }, "<m-k>", function()
      return ls.jumpable(-1) and "<Plug>luasnip-jump-prev" or "<S-Tab>"
    end, { expr = true, silent = true })

    -- vim.keymap.set({ "i" }, "<C-l>", function()
    --   --- @ diagnostic disable-next-line: missing-parameter
    --   ls.expand()
    -- end, { silent = true })
    --
    -- vim.keymap.set({ "i", "s" }, "<C-e>", function()
    --   if ls.choice_active() then
    --     ls.change_choice(1)
    --   end
    -- end, { silent = true })
  end,
}
