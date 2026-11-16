return {
  "aznhe21/actions-preview.nvim",
  enabled = true,
  opts = {
    backend = {
      "snacks",
      -- "telescope",
      -- "minipick",
      -- "nui",
    },
    snacks = {
      layout = require("modules.snacks.picker.layouts.custom-layouts").midscreen_dropdown_preview,
    },
  },
  keys = {
    {
      "<leader>cP",
      function()
        require("actions-preview").code_actions()
      end,
      desc = "Preview Code Actions",
      mode = { "n", "v" },
    },
  },
}
