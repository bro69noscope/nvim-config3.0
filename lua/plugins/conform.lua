return {
  "stevearc/conform.nvim",
  enabled = true,
  event = { "BufReadPre" },
  opts = {
    formatters_by_ft = {
      ["python"] = { "ruff_format" },
      ["yaml"] = { "prettier" },
      ["json"] = { "prettier" },
      ["jsonc"] = { "prettier" },
      ["json5"] = { "prettier" },
      ["html"] = { "prettier" },
      ["xml"] = { "prettier" }, -- with plugin npm install --save-dev @prettier/plugin-xml
      ["css"] = { "prettier" },
      ["scss"] = { "prettier" },
      ["less"] = { "prettier" },
      ["javascript"] = { "prettier" },
      ["typescript"] = { "prettier" },
      ["toml"] = { "taplo" },
      ["lua"] = { "stylua" },
      ["zsh"] = { "beautysh" },
      ["sh"] = { "shfmt" },
      ["cs"] = { "csharpier" },
    },
    formatters = {
      beautysh = {
        prepend_args = { "--indent-size", "2" },
      },
    },
    format_on_save = {
      timer = 500,
      lsp_fallback = true,
    },
  },
}
