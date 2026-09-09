return {
  "akinsho/bufferline.nvim",
  enabled = true,
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  event = { "BufReadPost", "BufNewFile" },
  keys = {
    { "<leader><BS>", "<cmd>BufferLinePick<CR>", desc = "Pick Tab" },
  },
  opts = {
    options = {
      mode = "tabs",
      max_name_length = 30,
      always_show_bufferline = false,
      name_formatter = function(buf)
        ---@cast buf {name: string, path: string, bufnr: number, buffers: table, tabnr: number}
        -- Check if tab has custom name
        if vim.t[buf.tabnr] and vim.t[buf.tabnr].custom_tabname then
          return vim.t[buf.tabnr].custom_tabname
        end
        -- Otherwise use default name
        return buf.name
      end,
    },
    highlights = {
      fill = {
        -- bg = "#1d1f2e",
        link = "StatusLine",
      },
    },
  },
}
