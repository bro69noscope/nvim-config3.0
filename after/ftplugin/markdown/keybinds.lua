local map = require("scripts.ui.whichkey-map").map

vim.keymap.del("n", "gO", { buffer = true })

local checkbox = require("lang.markdown.checkbox")

-- "g@_" operates on the current line. With a count ("3gmt"), it operates on 3 lines.
map(
  "n",
  "<leader>mt",
  checkbox.operator("g@_"),
  { buffer = 0, expr = true, desc = "Toggle checkbox", icon = "" }
)

-- "g@" in visual mode operates on the selection and leaves visual mode.
map(
  "x",
  "<leader>mt",
  checkbox.operator("g@"),
  { buffer = 0, expr = true, desc = "Toggle checkboxes", icon = "" }
)

map(
  "n",
  "<leader>mo",
  require("lang.markdown.obsidian.obsidian").open_current_file,
  { buffer = 0, desc = "Open file in Obsidian" }
)
