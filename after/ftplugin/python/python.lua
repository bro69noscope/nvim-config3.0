-- fix some dumb runtime builtin binds
vim.keymap.del({ "n", "x", "o" }, "]]", { buffer = true })
vim.keymap.del({ "n", "x", "o" }, "][", { buffer = true })
vim.keymap.del({ "n", "x", "o" }, "[[", { buffer = true })
vim.keymap.del({ "n", "x", "o" }, "[]", { buffer = true })

vim.keymap.del({ "n", "x", "o" }, "]m", { buffer = true })
vim.keymap.del({ "n", "x", "o" }, "[m", { buffer = true })
vim.keymap.del({ "n", "x", "o" }, "]M", { buffer = true })
vim.keymap.del({ "n", "x", "o" }, "[M", { buffer = true })
