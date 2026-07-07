return {
  "AndrewRadev/linediff.vim",
  enabled = true,
  lazy = true,
  event = { "BufReadPost", "BufNewFile" },
  keys = {
    {
      "<leader>ld",
      ":Linediff<cr>",
      mode = { "v", "n" },
      desc = "Linediff",
      noremap = true,
      silent = true,
      nowait = true,
    },
    {
      "<leader>la",
      ":LinediffAdd<cr>",
      mode = { "v", "n" },
      desc = "LinediffAdd",
      noremap = true,
      silent = true,
      nowait = true,
    },
    {
      "<leader>ls",
      ":LinediffShow<cr>",
      mode = { "v", "n" },
      desc = "LinediffShow",
      noremap = true,
      silent = true,
    },
    {
      "<leader>ll",
      ":LinediffLast<cr>",
      mode = { "v", "n" },
      desc = "LinediffLast",
      noremap = true,
      silent = true,
      nowait = true,
    },
  },
  cmd = {
    "Linediff",
  },
  config = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "LinediffBufferReady",
      callback = function()
        local diff_sanitize = require("scripts.ui.diff-sanitize")
        diff_sanitize.disable_diff_features()
        vim.api.nvim_buf_set_keymap(0, "n", "q", ":LinediffReset<CR>", { noremap = true })

        vim.keymap.set("n", "<C-j>", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          end
        end, { buffer = 0 })

        vim.keymap.set("n", "<C-k>", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          end
        end, { buffer = 0 })

        vim.api.nvim_create_autocmd("TabClosed", {
          callback = function()
            diff_sanitize.re_enable_diff_features()
          end,
        })
      end,
    })
  end,
}
