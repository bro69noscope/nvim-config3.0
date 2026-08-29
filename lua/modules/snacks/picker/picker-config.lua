local M = {}
M.path_inserts = require("modules.snacks.picker.actions.path-inserts")
M.setup_picker_keys = require("modules.snacks.picker.keys.setup-picker-keys")
M.case_aware_grep = require("modules.snacks.picker.finders.case-aware-grep")
M.patched_jumps = require("modules.snacks.picker.finders.patched-jumps")
M.filter_builtins = require("modules.snacks.picker.filters.filter-builtins")
M.explorer_config = require("modules.snacks.picker.explorer.explorer-config")
M.setup_flash = require("modules.snacks.picker.setup-flash")
M.input_grep_globs = require("modules.snacks.picker.actions.input-grep-globs")
M.toggle_and_search = require("modules.snacks.picker.actions.toggle-grep-and-search")
M.toggle_smartcase = require("modules.snacks.picker.actions.toggle-smartcase").toggle_case
M.append_to_qflist = require("modules.snacks.picker.actions.append-to-qflist").qflist_append
M.persist_flags = require("modules.snacks.picker.persist-flags")

local shared_deps = {
  case_aware_grep = M.case_aware_grep,
  setup_picker_keys = M.setup_picker_keys,
  input_grep_globs = M.input_grep_globs,
  toggle_and_search = M.toggle_and_search,
  toggle_smartcase = M.toggle_smartcase,
}

M.shared_configs = require("modules.snacks.picker.shared-configs")

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
    grep_word = M.shared_configs.make_grep_source("grep_word", shared_deps),
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
    grep = M.shared_configs.make_grep_source("grep", shared_deps),
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
    qflist_append = function(picker)
      M.append_to_qflist(picker)
    end,
    flash = M.setup_flash,
    custom_toggle_hidden = function(picker)
      if not picker or not picker.opts then
        return
      end
      picker.opts.hidden = not picker.opts.hidden
      M.persist_flags.set("explorer", "hidden", picker.opts.hidden)
      picker:find()
    end,
    custom_toggle_ignored = function(picker)
      if not picker or not picker.opts then
        return
      end
      picker.opts.ignored = not picker.opts.ignored
      M.persist_flags.set("explorer", "ignored", picker.opts.ignored)
      picker:find()
    end,
  },
  win = {
    input = {
      keys = {
        ["<Down>"] = { "history_forward", mode = { "i", "n" } },
        ["<Up>"] = { "history_back", mode = { "i", "n" } },
        ["<c-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
        ["<c-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
        ["-"] = { "insert_relative_path", mode = { "n" } },
        ["="] = { "insert_absolute_path", mode = { "n" } },
        -- ["<bs>"] = { "insert_python_import_path", mode = { "n" } }, NOTE: idk about keeping this
        ["+"] = { "clip_full_path", mode = { "n" } },
        [RightWindowBind] = { "focus_preview", mode = { "i", "n" } },
        [LeftWindowBind] = { "focus_list", mode = { "i", "n" } },
        ["<a-s>"] = { "flash", mode = { "n", "i" } },
        ["O"] = { { "pick_win", "jump" }, mode = { "n" } },
        ["<a-q>"] = { "qflist_append", mode = { "n", "i" } },
        ["<a-h>"] = { "custom_toggle_hidden", mode = { "n", "i" } },
        ["<a-i>"] = { "custom_toggle_ignored", mode = { "n", "i" } },
      },
    },
    list = {
      keys = {
        ["O"] = { { "pick_win", "jump" } },
        ["<a-h>"] = { "custom_toggle_hidden", mode = { "n", "i" } },
        ["<a-i>"] = { "custom_toggle_ignored", mode = { "n", "i" } },
        [RightWindowBind] = { "focus_preview", mode = { "i", "n" } },
        [LeftWindowBind] = { "focus_list", mode = { "i", "n" } },
      },
    },
    preview = {
      keys = {
        [LeftWindowBind] = { "focus_list", mode = { "i", "n" } },
      },
    },
  },
}
