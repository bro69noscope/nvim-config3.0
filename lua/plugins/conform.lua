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
