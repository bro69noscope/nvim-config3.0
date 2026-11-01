return {
  "stevearc/conform.nvim",
  enabled = true,
  event = { "BufReadPre" },
  opts = {
    formatters_by_ft = {
      ["python"] = { "ruff_format", "ruff_organize_imports" },
      ["yaml"] = { "prettier" },
      ["json"] = { "prettier" },
      ["jsonc"] = { "prettier" },
      ["json5"] = { "prettier" },
      ["html"] = { "prettier" },
      ["xml"] = { lsp_format = "prefer" },
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
      ["ps1"] = { lsp_format = "prefer" },
      ["autohotkey"] = { lsp_format = "prefer" },
      ["qss"] = { "prettier_qss" },
    },
    formatters = {
      beautysh = {
        prepend_args = { "--indent-size", "2" },
      },
      prettier_qss = {
        inherit = "prettier",
        prepend_args = { "--parser", "css" },
      },
    },
    format_on_save = function(bufnr)
      if vim.bo[bufnr].filetype == "ps1" then
        require("lang.powershell.lsp.powershell-lsp-settings").sync_buffer(bufnr)
      end
      return {}
    end,
  },
}
