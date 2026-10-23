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
  "css",
  "javascript",
}

vim.filetype.add({ extension = { qss = "qss" } })
vim.treesitter.language.register("css", "qss")

require("nvim-treesitter").install(parsers)
