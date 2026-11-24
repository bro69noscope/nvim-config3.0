return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- use latest release, remove to use latest commit
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    legacy_commands = false, -- this will be removed in 4.0.0
    workspaces = {
      {
        name = "streaming",
        path = "~/myfiles/documents/obsidian-vaults/streaming",
      },
    },

    callbacks = {
      enter_note = function(note)
        local map = require("scripts.ui.whichkey-map").map
        local buf = note.bufnr

        map(
          "n",
          "<leader>mn",
          vim.lsp.buf.rename,
          { buffer = buf, desc = "Rename note", icon = "✏️" }
        )
        map(
          "n",
          "<leader>mr",
          vim.lsp.buf.references,
          { buffer = buf, desc = "Note references", icon = "🔗" }
        )
        map(
          "n",
          "<leader>mh",
          vim.lsp.buf.document_symbol,
          { buffer = buf, desc = "Note headings", icon = "📑" }
        )
        map(
          "n",
          "<leader>ma",
          vim.lsp.buf.code_action,
          { buffer = buf, desc = "Note actions", icon = "💡" }
        )
      end,
    },
  },
}
