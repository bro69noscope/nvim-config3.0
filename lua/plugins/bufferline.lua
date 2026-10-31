local function move(dir)
  return function()
    -- BufferLineMove breaks in tabs mode (treats tab ids as buffer ids)
    local n = vim.fn.tabpagenr()
    local last = vim.fn.tabpagenr("$")
    if dir == "Prev" then
      vim.cmd("tabmove " .. (n == 1 and "$" or "-1"))
    else
      vim.cmd("tabmove " .. (n == last and "0" or "+1"))
    end
  end
end

return {
  "akinsho/bufferline.nvim",
  enabled = true,
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  event = { "BufReadPost", "BufNewFile" },
  keys = {
    { "<leader><BS>", "<cmd>BufferLinePick<CR>", desc = "Pick Tab" },
    { "<S-Home>", move("Prev"), desc = "Move buffer left" },
    { "<S-End>", move("Next"), desc = "Move buffer right" },
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
