return {
  "folke/snacks.nvim",
  enabled = true,
  lazy = false,
  init = function()
    vim.api.nvim_set_hl(0, "SnacksPickerMatch", { link = "CustomMatch" })
    if true then
      _G.MainFileExplorer = "snacks"
    end
    require("modules.snacks.toggle.toggle-setup")
    require("modules.snacks.setup-debug")
  end,
  opts = {
    -- bigfile = { enabled = true },
    dashboard = require("modules.snacks.dashboard.dashboard-config"),
    -- explorer = { enabled = true },
    -- indent = { enabled = true },
    input = {
      enabled = false,
      win = {
        relative = "cursor",
        -- row = math.floor(vim.o.lines * 0.5) - 2,
      },
    },
    notifier = {
      enabled = true,
      filter = function(notif)
        if notif.msg:find("Plugin Updates") then
          notif.timeout = 1000
        end
        return true
      end,
    },
    -- quickfile = { enabled = true },
    -- scope = { enabled = true },
    -- scroll = { enabled = true },
    toggle = { enabled = true }, -- Setup is made in init, necessary? maybe idk why.
    statuscolumn = { enabled = true },
    words = { enabled = true },
    picker = require("modules.snacks.picker.picker-config"),
  },
  keys = {
    -- Explorer
    {
      "<leader>e",
      function()
        if pcall(require, "neo-tree") then
          vim.cmd("Neotree close")
        end
        require("snacks").explorer()
      end,
      desc = "Toggle Snacks Explorer",
    },

    {
      "<leader>E",
      function()
        if pcall(require, "neo-tree") then
          vim.cmd("Neotree close")
        end
        require("snacks").explorer({ follow_file = false })
      end,
      desc = "Toggle Snacks Explorer (No Follow File)",
    },

    -- Words
    {
      "]r",
      function()
        local repeat_reverse = require("modules.snacks.words.repeat-reverse")
        local next_ref, _ = repeat_reverse.setup_snacks_words()
        next_ref()
      end,
      desc = "Next Snacks Word",
    },
    {
      "[r",
      function()
        local repeat_reverse = require("modules.snacks.words.repeat-reverse")
        local _, prev_ref = repeat_reverse.setup_snacks_words()
        prev_ref()
      end,
      desc = "Previous Snacks Word",
    },
    -- Custom pickers
    {
      "<leader>c/",
      function()
        local grep_qfix = require("modules.snacks.picker.grep-quickfix-files")
        grep_qfix.grep_qf_files()
      end,
      desc = "Grep Quickfix Files",
    },
    {
      "<leader>gm",
      function()
        Snacks.picker.git_branches({
          on_show = function(picker)
            picker.input:set("branch:")
          end,
        })
      end,
      desc = "Checkout Branch",
    },
   -- stylua: ignore start

    -- Default grepping (without the finder overriden by egrepify)
    { "<leader>sG", function() Snacks.picker.grep({ finder = "grep", }) end, desc = "Grep (default)", },

    -- Notifier
    {"<leader>nn", function() Snacks.notifier.show_history() end, desc = "Notifier History"},

   -- Top Pickers & Explorer
    { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
    { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>s:", function() Snacks.picker.command_history() end, desc = "Command History" },
    -- { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    -- { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git Files" },
    -- { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
    { "<leader>gL", function() Snacks.picker.git_log_line() end, desc = "Pick Log Line" },
    { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Pick Log File" },
    { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Pick Log (All)" },
    { "<leader>gM", function() Snacks.picker.git_branches() end, desc = "Pick Branches " },
    { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Pick Status" },
    { "<leader>gt", function() Snacks.picker.git_stash() end, desc = "Pick Stash" },
    { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Pick Diff (Hunks)" },
    { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
    { "<leader>s,", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
    { "<leader>sw", function() Snacks.picker.grep_word({
      regex = true,
      args = {},
    }) end, desc = "Visual selection or word", mode = { "n", "x" } },
    { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
    { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Search History" },
    { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
    { "<leader>sC", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config"), title = "Config Files" }) end,
    desc = "Find Config File", },
    { "<leader>sc", function() Snacks.picker.commands() end, desc = "Commands" },
    { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
    { "<leader>sf", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
    { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
    { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
    { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
    { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
    { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
    { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
    { "<leader>sn", function() Snacks.picker.notifications() end, desc = "Notification History" },
    { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
    { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
    { "<leader>sr", function() Snacks.picker.recent() end, desc = "Recent" },
    { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
    { "<leader>st", function() Snacks.picker.todo_comments() end, desc = "Todo comments" },
    { "<leader>sT", function () Snacks.picker.todo_comments({
      keywords = { "TODO", "FIX", "FIXME" } }) end, desc = "Todo/Fix/Fixme" },
    { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
    { "<leader>uS", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
    { "zp", function() Snacks.picker.spelling() end, desc = "Spelling Picker" },
    -- LSP
    { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
    { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
    { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { "gR", function() Snacks.picker.lsp_references({ include_current = true }) end, desc = "References (include current)"},
    { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
    { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
    { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
    { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },

    -- stylua: ignore end
  },
}
