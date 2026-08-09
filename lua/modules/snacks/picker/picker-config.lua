local M = {}
M.path_inserts = require("modules.snacks.picker.actions.path-inserts")
M.setup_all_keys = require("modules.snacks.picker.keys.setup-all-keys")
M.case_aware_grep = require("modules.snacks.picker.finders.case-aware-grep")
M.shared_grep_config = require("modules.snacks.picker.shared-configs")

---@param source string explicit source name, e.g. "grep" or "grep_word"
local function make_grep_source(source)
  return {
    finder = M.case_aware_grep.wrap(require("modules.snacks.picker.finders.egrepify").egrepify),
    layout = "grep_vertical",
    win = {
      input = {
        keys = M.setup_all_keys.setup_grep_input_keys(nil, nil, source),
      },
    },
    actions = {
      toggle_and_search = require("modules.snacks.picker.actions.toggle-grep-and-search"),
      toggle_smartcase = require("modules.snacks.picker.actions.toggle-smartcase"),
      grep_globs_input = require("modules.snacks.picker.actions.input-grep-globs").make_action(
        nil,
        nil,
        source
      ),
    },
  }
end

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
      finder = function()
        -- NOTE: ai code to review, seems to work. Fixes crash on invalid buffer preview.
        -- TODO: create issue
        local jumps = vim.fn.getjumplist()[1]
        local items = {}
        for _, jump in ipairs(jumps) do
          local buf_valid = jump.bufnr and jump.bufnr > 0 and vim.api.nvim_buf_is_valid(jump.bufnr)
          local buf = buf_valid and jump.bufnr or nil
          local file = jump.filename
          if not file and buf then
            file = vim.api.nvim_buf_get_name(buf)
          end

          -- skip entries with no usable buffer AND no file that still exists on disk
          local file_exists = file and file ~= "" and vim.uv.fs_stat(file) ~= nil
          if buf or file_exists then
            local line
            if buf then
              line = vim.api.nvim_buf_get_lines(buf, jump.lnum - 1, jump.lnum, false)[1]
            end
            local label = tostring(#jumps - #items)
            table.insert(items, 1, {
              label = Snacks.picker.util.align(label, #tostring(#jumps), { align = "right" }),
              buf = buf,
              line = line,
              text = table.concat({ file, line }, " "),
              file = file,
              pos = jump.lnum and jump.lnum > 0 and { jump.lnum, jump.col } or nil,
            })
          end
        end
        return items
      end,
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
      filter = require("modules.snacks.picker.filters.filter-builtins").filter_recent,
    },
    explorer = require("modules.snacks.explorer.explorer-config"),
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
    flash = require("modules.snacks.picker.setup-flash"),
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
