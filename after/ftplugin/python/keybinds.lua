local constants = require("lang.python.constants")
local strictness = require("modules.snacks.toggle.custom-toggles.python-lsp-strictness")

strictness.py_lsp_strictness_toggle:map("<leader>lt")

-- fix some retarded runtime builtin binds
vim.keymap.del({ "n", "x", "o" }, "]]", { buffer = true })
vim.keymap.del({ "n", "x", "o" }, "][", { buffer = true })
vim.keymap.del({ "n", "x", "o" }, "[[", { buffer = true })
vim.keymap.del({ "n", "x", "o" }, "[]", { buffer = true })

vim.keymap.del({ "n", "x", "o" }, "]m", { buffer = true })
vim.keymap.del({ "n", "x", "o" }, "[m", { buffer = true })
vim.keymap.del({ "n", "x", "o" }, "]M", { buffer = true })
vim.keymap.del({ "n", "x", "o" }, "[M", { buffer = true })

-- Buffer-local, so these override the global treesitter-textobjects ]k [k.
vim.keymap.set("n", "]k", constants.next_constant, { buffer = true, desc = "Next .py constant" })
vim.keymap.set(
  "n",
  "[k",
  constants.prev_constant,
  { buffer = true, desc = "Previous .py constant" }
)
