local M = {}
M.path_inserts = require("modules.snacks.picker.actions.path-inserts")
M.setup_all_keys = require("modules.snacks.picker.keys.setup-all-keys")
M.case_aware_grep = require("modules.snacks.picker.finders.case-aware-grep")
M.shared_grep_config = require("modules.snacks.picker.shared-configs")
M.patched_jumps = require("modules.snacks.picker.finders.patched-jumps")
M.filter_builtins = require("modules.snacks.picker.filters.filter-builtins")
M.explorer_config = require("modules.snacks.picker.explorer.explorer-config")
M.setup_flash = require("modules.snacks.picker.setup-flash")

return {
  formatters = { file = { truncate = 80, filename_first = true } },
  layouts = require("modules.snacks.picker.layouts.custom-layouts"),
  previewers = {
    diff = {
      builtin = false,
      cmd = { "delta" },
    },
    git = {
      builtin = false,
    },
  },
  sources = {
    lsp_definitions = {
      jump = { reuse_win = false }, -- Prevent using a different window for gd, etc.
    },
    lsp_declarations = {
      jump = { reuse_win = false },
    },
    lsp_implementations = {
      jump = { reuse_win = false },
    },
    lsp_references = {
      jump = { reuse_win = false },
    },
    lsp_type_definitions = {
      jump = { reuse_win = false },
    },
    qflist = {
      layout = "grep_vertical",
    },
    grep_buffers = {
      layout = "grep_vertical",
    },
    grep_word = M.shared_grep_config.make_grep_source("grep_word"),
    jumps = {
      layout = "grep_vertical",
      finder = M.patched_jumps.patched_jumps_finder,
      format = "file",
      main = { current = true },
    },
    todo_comments = {
      layout = "grep_vertical",
    },
    command_history = {
      layout = "midscreen_dropdown",
    },
    search_history = {
      layout = "midscreen_dropdown",
    },
    recent = {
      filter = M.filter_builtins.filter_recent,
    },
    explorer = M.explorer_config,
    grep = M.shared_grep_config.make_grep_source("grep"),
  },
  actions = {
    insert_absolute_path = function(picker)
      M.path_inserts.insert_absolute_path(picker)
    end,
    insert_relative_path = function(picker)
      M.path_inserts.insert_relative_path(picker)
    end,
    insert_python_import_path = function(picker)
      M.path_inserts.insert_python_import_path(picker)
    end,
    clip_full_path = function(picker)
      M.path_inserts.clip_full_path(picker)
    end,
    flash = M.setup_flash,
  },
  win = {
    input = {
      keys = {
        ["<c-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
        ["<c-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
        ["-"] = { "insert_relative_path", mode = { "n" } },
        ["="] = { "insert_absolute_path", mode = { "n" } },
        -- ["<bs>"] = { "insert_python_import_path", mode = { "n" } }, NOTE: idk about keeping this
        ["+"] = { "clip_full_path", mode = { "n" } },
        ["<c-l>"] = { "focus_preview", mode = { "i", "n" } },
        ["<c-h>"] = { "focus_list", mode = { "i", "n" } },
        ["<a-s>"] = { "flash", mode = { "n", "i" } },
        ["O"] = { { "pick_win", "jump" }, mode = { "n" } },
      },
    },
    list = {
      keys = {
        ["O"] = { { "pick_win", "jump" } },
      },
    },
  },
}
