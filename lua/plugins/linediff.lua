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
    local diff_sanitize = require("scripts.ui.diff-sanitize")

    -- Horizontal diff if the line is long
    local function split_long_linediff()
      local longest_line = 0
      local max_len = 70

      for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
        longest_line = math.max(longest_line, #line)
      end

      if longest_line > max_len then
        vim.cmd("wincmd K")
      end
    end

    local linediff_tabs = {}
    vim.api.nvim_create_autocmd("User", {
      pattern = "LinediffBufferReady",
      callback = function()
        local tab = vim.api.nvim_get_current_tabpage()

        linediff_tabs[tab] = true

        split_long_linediff()
        diff_sanitize.disable_diff_features()

        vim.keymap.set("n", "q", function()
          vim.cmd("LinediffReset")
          vim.cmd("tabclose")
        end, {
          buffer = 0,
          silent = true,
        })

        vim.keymap.set("n", NextDiffChangeBind, function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          end
        end, { buffer = 0 })

        vim.keymap.set("n", PreviousDiffChangeBind, function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          end
        end, { buffer = 0 })
      end,
    })

    vim.api.nvim_create_autocmd("TabClosed", {
      callback = function()
        for tab in pairs(linediff_tabs) do
          if not vim.api.nvim_tabpage_is_valid(tab) then
            linediff_tabs[tab] = nil
            diff_sanitize.re_enable_diff_features()
          end
        end
      end,
    })
  end,
}
