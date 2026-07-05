return {
  "stevearc/quicker.nvim",
  enabled = false,
  event = "FileType qf",
  ---@module "quicker"
  ---@type quicker.SetupOptions
  opts = {
    -- defaults
    -- borders = {
    --   vert = "┃",
    --   -- Strong headers separate results from different files
    --   strong_header = "━",
    --   strong_cross = "╋",
    --   strong_end = "┫",
    --   -- Soft headers separate results within the same file
    --   soft_header = "╌",
    --   soft_cross = "╂",
    --   soft_end = "┨",
    -- },
    borders = {
      vert = "│",
      strong_header = "─",
      strong_cross = "┼",
      strong_end = "┤",
      soft_header = "┄",
      soft_cross = "┼",
      soft_end = "┤",
    },
    keys = {
      { ">", "<cmd>lua require('quicker').expand()<CR>", desc = "Expand quickfix content" },
      { "<", "<cmd>lua require('quicker').collapse()<CR>", desc = "Collapse quickfix content" },
    },
    constrain_cursor = false,
    highlight = {
      -- Use treesitter highlighting
      treesitter = true,
      -- Use LSP semantic token highlighting
      lsp = true,
      -- Load the referenced buffers to apply more accurate highlights (may be slow)
      load_buffers = true,
    },
  },
}
