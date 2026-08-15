local parsers = {
  "lua",
  "python",
  "typescript",
  "tsx",
  "json",
  "json5",
  "c_sharp",
  "powershell",
  "bash",
  "markdown",
  "markdown_inline",
  "vim",
  "vimdoc",
  "query",
}

require("nvim-treesitter").install(parsers)
