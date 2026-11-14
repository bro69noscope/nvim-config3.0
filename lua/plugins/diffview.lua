return {
  -- "sindrets/diffview.nvim",
  "dlyongemallo/diffview.nvim", -- fork of repo with some fixes over last 2 years
  enabled = true,
  keys = {
    { "<leader>god", "<cmd>DiffviewOpen<cr>", desc = "DiffView" },
    { "<leader>goh", mode = { "n" }, "<cmd>DiffviewFileHistory<cr>", desc = "File history" },
    { "<leader>goh", mode = { "v" }, ":DiffviewFileHistory<cr>", desc = "Lines history" },
    { "<leader>got", "<cmd>DiffviewFileHistory %<cr>", desc = "This file history" },
  },
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewLog" },
  config = function()
    require("modules.diffview.highlights").setup()
    require("modules.diffview.autocmds").setup()

    local actions = require("diffview.actions")
    local hooks = require("modules.diffview.hooks")
    local jump_sections = require("modules.diffview.jump-sections")
    local change_nav = require("modules.diffview.change-nav")
    local close_and_jump = require("modules.diffview.close-and-jump").close_and_jump

    require("diffview").setup({
      wrap_entries = false, -- Fork opt only
      hooks = {
        view_opened = hooks.view_opened,
        view_closed = hooks.view_closed,
        diff_buf_read = hooks.diff_buf_read,
        diff_buf_win_enter = hooks.diff_buf_win_enter,
      },
      enhanced_diff_hl = true,
      view = {
        merge_tool = {
          layout = "diff3_mixed",
        },
        default = {
          layout = "diff2_vertical",
        },
      },
      keymaps = {
        view = {
          { "n", "q", actions.close, { desc = "Close diffview" } },
          { "n", "Q", close_and_jump, { desc = "Close diffview and jump to cursor pos" } },
          { "n", "-", actions.toggle_stage_entry, { desc = "Toggle stage file" } },
          {
            "n",
            vim.g.maplocalleader .. "s",
            jump_sections.jump_to_next_section,
            { desc = "Jump between changes/staged sections" },
          },
          { "n", NextDiffChangeBind, change_nav.next_change, { desc = "Next change or file" } },
          {
            "n",
            PrevDiffChangeBind,
            change_nav.prev_change,
            { desc = "Previous change or file" },
          },
          { "n", "]x", false, { desc = "diffview_ignore" } },
          { "n", "[x", false, { desc = "diffview_ignore" } },
          {
            "n",
            NextDiffConflictBind,
            change_nav.next_conflict,
            { desc = "Next conflict or file" },
          },
          {
            "n",
            PrevDiffConflictBind,
            change_nav.prev_conflict,
            { desc = "Previous conflict or file" },
          },
        },
        file_panel = {
          { "n", "q", actions.close, { desc = "Close diffview" } },
          { "n", "Q", close_and_jump, { desc = "Close diffview and jump to cursor pos" } },
          { "n", "s", false, { desc = "diffview_ignore" } }, -- lets us use flash in diffview
          { "n", "-", actions.toggle_stage_entry, { desc = "Toggle stage file" } },
          { "n", "l", actions.focus_entry, { desc = "Open and focus file" } },
          {
            "n",
            vim.g.maplocalleader .. "s",
            jump_sections.jump_to_next_section,
            { desc = "Jump between changes/staged sections" },
          },
        },
        file_history_panel = {
          { "n", "q", actions.close, { desc = "Close diffview" } },
          { "n", "Q", close_and_jump, { desc = "Close diffview and jump to cursor pos" } },
          { "n", "l", actions.focus_entry, { desc = "Open and focus file" } },
        },
      },
    })
  end,
}
