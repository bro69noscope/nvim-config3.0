local M = {}

M.lemminx = {
  settings = {
    xml = {
      validation = {
        noGrammar = "ignore",
      },
      format = {
        enabled = true,
        splitAttributes = false,
        preservedNewlines = 1,
        -- joinContentLines = true,

        -- !!dangerous, can break .props files due to literal line breaks in between tags
        -- maxLineWidth = 80,
      },
    },
  },
}

return M
