return {
  "jay-babu/mason-null-ls.nvim",
  enabled = true,
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "nvimtools/none-ls.nvim",
  },
  config = function()
    local h = require("null-ls.helpers")
    local methods = require("null-ls.methods")

    require("mason-null-ls").setup({
      ensure_installed = {
        "taplo",
        -- "pylint",
        "stylua",
        "prettier",
        "shfmt",
        "beautysh",
        "csharpier",
      },
      automatic_installation = true,
    })

    local taplo = h.make_builtin({
      name = "taplo",
      method = methods.internal.FORMATTING,
      filetypes = { "toml" },
      generator_opts = {
        command = "taplo",
        args = { "format", "-" },
        to_stdin = true,
      },
      factory = h.formatter_factory,
    })

    require("null-ls").setup({
      sources = {
        taplo,
      },
      autostart = true,
    })
  end,
}
