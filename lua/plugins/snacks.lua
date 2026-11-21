---Keymap callback that opens a picker from modules/snacks/picker/pickers/.
---@param name string module file name, without .lua
local function custom_picker(name)
  return function()
    require("modules.snacks.picker.pickers." .. name).open()
  end
end

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
    require("modules.snacks.picker.explorer.safe-copy").setup()
    require("modules.snacks.picker.persist-flags").setup()
  end,
  opts = {
    styles = {
      -- window of Snacks.notifier.show_history() (default 0.6 x 0.6)
      notification_history = { width = 0.8, height = 0.85 },
    },
    terminal = {
      win = {
        keys = {
          term_normal = false,
        },
      },
    },
    image = { enabled = not OnNeovide }, --TODO: check when neovide supports image preview
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
    words = { enabled = true, jumplist = false },
    picker = require("modules.snacks.picker.picker-config"),
  },
  config = function(_, opts)
    require("snacks").setup(opts)
    require("modules.snacks.rename-debug").setup()
    require("modules.snacks.move-debug").setup()
  end,
  keys = {

    --
    -- Explorer:
    --

    {
      ToggleExplorerBind,
      "<cmd>ExplorerToggleNoFocus<cr>",
    },

    {
      "<leader>e",
      function()
        if pcall(require, "neo-tree") then
          vim.cmd("Neotree close")
        end
        require("modules.snacks.picker.explorer.open-with-flags").toggle()
      end,
      desc = "Toggle Snacks Explorer",
    },

    {
      "<leader>E",
      function()
        if pcall(require, "neo-tree") then
          vim.cmd("Neotree close")
        end
        require("modules.snacks.picker.explorer.open-with-flags").open({ follow_file = false })
      end,
      desc = "Snacks Explorer No Follow File",
    },

    {
      "<M-r>",
      function()
        require("modules.snacks.picker.explorer.force-reveal").reveal_current()
      end,
      desc = "Reveal file in explorer",
    },

    --
    -- Words:
    --

    {
      "]r",
      function()
        local repeat_reverse = require("modules.snacks.words.repeat-reverse")
        local next_ref, _ = repeat_reverse.setup_snacks_words()
        repeat_reverse.snapshot()
        local pos = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_buf_set_mark(0, Automated_marks.snacks_words_jumps.key, pos[1], pos[2], {})
        next_ref()
      end,
      desc = "Next Snacks Word",
    },

    {
      "[r",
      function()
        local repeat_reverse = require("modules.snacks.words.repeat-reverse")
        local _, prev_ref = repeat_reverse.setup_snacks_words()
        repeat_reverse.snapshot()
        local pos = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_buf_set_mark(0, Automated_marks.snacks_words_jumps.key, pos[1], pos[2], {})
        prev_ref()
      end,
      desc = "Previous Snacks Word",
    },

    --
    -- Custom pickers:
    --

    {
      "<leader>sW",
      custom_picker("grep-bounded-word"),
      desc = "Selection or word (bounds)",
      mode = { "n", "x" },
    },
    { "<c-t>", custom_picker("smart-from-insert"), mode = { "i" } },
    { "<leader>,", custom_picker("buffers-clean"), desc = "Buffers (clean)" },
    { "<leader>c/", custom_picker("grep-quickfix-files"), desc = "Grep Quickfix Files" },
    { "<leader>gm", custom_picker("checkout-branch"), desc = "Checkout Branch" },
    { "<leader>g.", custom_picker("git-status-cwd"), desc = "Git Status (cwd)" },
    { "<leader>ge", custom_picker("git-status-all"), desc = "Git Status (+submodules files)" },
    { "<leader>sl", custom_picker("log-files"), desc = "Find .log files / log dirs" },
    { "<leader>sm", custom_picker("user-marks"), desc = "Marks" },
    { "<leader>sG", custom_picker("grep-default"), desc = "Grep (default)" },
    {
      "<leader>sw",
      custom_picker("grep-word"),
      desc = "Visual selection or word",
      mode = { "n", "x" },
    },
    { "<leader>sC", custom_picker("config-files"), desc = "Find Config File" },
    {
      '<leader>"',
      custom_picker("files-from-selection"),
      mode = "x",
      desc = "Find Files (selection)",
    },
    { "<leader>sT", custom_picker("todo-fix"), desc = "Todo/Fix/Fixme" },
    { "gR", custom_picker("references-with-current"), desc = "References (include current)" },

   -- stylua: ignore start

    -- Notifier
    {"<leader>nn", function() Snacks.notifier.show_history() end, desc = "Notifier History"},

   -- Top Pickers & Explorer
    { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
    { "<leader>;", function() Snacks.picker.buffers() end, desc = "All Buffers" },
    { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
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
    { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
    { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Search History" },
    { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
    { "<leader>sc", function() Snacks.picker.commands() end, desc = "Commands" },
    { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
    { "<leader>\"", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
    { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
    { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
    { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
    { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>sL", function() Snacks.picker.loclist() end, desc = "Location List" },
    -- { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
    { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
    { "<leader>sn", function() Snacks.picker.notifications() end, desc = "Notification History" },
    { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
    { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
    { "<leader>sr", function() Snacks.picker.recent() end, desc = "Recent" },
    { "<leader>s.", function() Snacks.picker.resume() end, desc = "Resume" },
    { "<leader>st", function() Snacks.picker.todo_comments() end, desc = "Todo comments" },
    { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
    { "<leader>uS", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
    { "zp", function() Snacks.picker.spelling() end, desc = "Spelling Picker" },
    -- LSP
    { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
    { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
    { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
    { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
    { "<leader>sf", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols in [F]ile" },
    { "<leader>se", function() Snacks.picker.lsp_workspace_symbols() end,
    desc = "LSP Symbols [E]verywhere" },

    -- stylua: ignore end
  },
}
