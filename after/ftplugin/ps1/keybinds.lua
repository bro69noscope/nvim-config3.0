local goto_first = require("lang.powershell.goto-first-in-function")

vim.keymap.set(
  "n",
  "g;",
  goto_first.goto_first_in_function,
  { buffer = true, desc = "goto first occurence in function" }
)
