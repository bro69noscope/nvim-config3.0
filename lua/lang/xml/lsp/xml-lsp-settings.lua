local M = {}

M.lemminx = {
  settings = {
    xml = {
      format = {
        enabled = true,
        splitAttributes = true,
        preservedNewlines = 1,
        maxLineWidth = 80, -- seems to have to be shorter than the actual line length idk
      },
    },
  },
}

return M
