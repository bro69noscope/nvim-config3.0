require("modules.snacks.picker.explorer.fix-files-follow")
require("modules.snacks.picker.explorer.fix-input-clear-onsave")
local open_with_flags = require("modules.snacks.picker.explorer.open-with-flags")
local grep_actions = require("modules.snacks.picker.actions.grep-actions")
local explorer_actions = require("modules.snacks.picker.explorer.actions.actions")
local launch_picker_with_explorer_return =
  require("modules.snacks.picker.explorer.actions.launch-with-explorer-return")

local toggle_no_follow = function()
  local persist_flags = require("modules.snacks.picker.persist-flags")
  local no_follow = persist_flags.get("explorer", "no_follow", false)
  open_with_flags.open({ follow_file = no_follow })
end

local set_cwd_here = function(picker, item)
  if not item or not item.file then
    return
  end

  local path = item.file

  if vim.fn.isdirectory(path) ~= 1 then
    path = vim.fn.fnamemodify(path, ":h")
  end

  vim.cmd("cd " .. vim.fn.fnameescape(path))
end

local focus_right_win = function()
  -- Avoids having to go right twice from the input window
  vim.cmd("stopinsert")
  vim.cmd("wincmd l")
  -- if we are still in the Snacks picker list, go right again
  vim.schedule(function()
    if vim.bo.filetype == "snacks_picker_list" then
      vim.cmd("wincmd l")
    end
  end)
end

return {
  actions = {
    -- fundamentals
    focus_right_win = focus_right_win,
    set_cwd_here = set_cwd_here,
    toggle_no_follow = toggle_no_follow,
    grep_filename = function(picker, item)
      grep_actions.grep_for_filename(picker, item, { launch = launch_picker_with_explorer_return })
    end,
    grep_full_filename = function(picker, item)
      grep_actions.grep_for_filename_with_ext(
        picker,
        item,
        { launch = launch_picker_with_explorer_return }
      )
    end,
    -- from actions/
    grep_in_dir = explorer_actions.grep_in_dir,
    grep_in_dir_default = function(picker, item)
      return explorer_actions.grep_in_dir(picker, item, { default_grep = true })
    end,
    search_files_in_dir = explorer_actions.search_files_in_dir,
    grug_far_refactor_python_imports = explorer_actions.grug_far_refactor_imports,
    open_with_system = explorer_actions.open_with_system,
    expand_recursive = explorer_actions.expand_recursive,
  },
  toggles = {
    no_follow_file = "NF",
  },
  win = {
    list = {
      keys = {
        ["gf"] = { "grep_filename", desc = "Grep fname" },
        ["gF"] = { "grep_full_filename", desc = "Grep fname + .ext" },
        ["gd"] = { "grep_in_dir", desc = "Grep in dir" },
        ["gD"] = { "grep_in_dir_default", desc = "Grep in dir (default)" },
        ["gr"] = { "grug_far_refactor_python_imports", desc = "Grugfar python imports" },
        ["g."] = { "set_cwd_here", desc = "Set cwd to dir" },
        ["go"] = { "open_with_system", desc = "Open with system" },
        ["X"] = { "expand_recursive", desc = "Expand recursively" },
        ["fd"] = { "search_files_in_dir", desc = "Search files in dir" },
        ["<BS>"] = false,
        [DownWindowBind] = false,
        [UpWindowBind] = false,
        [RightWindowBind] = false,
        ["<esc>"] = {
          function()
            vim.cmd("wincmd p")
          end,
          desc = "Exit to prev window",
        },
        ["<M-a>"] = { "toggle_no_follow", desc = "Toggle no-follow" },
      },
    },
    input = {
      keys = {
        ["gf"] = { "grep_filename", desc = "Grep fname" },
        ["gF"] = { "grep_full_filename", desc = "Grep fname + .ext" },
        ["gd"] = { "grep_in_dir", desc = "Grep in dir" },
        ["gD"] = { "grep_in_dir_default", desc = "Grep in dir (default)" },
        ["gr"] = { "grug_far_refactor_python_imports", desc = "Grugfar python imports" },
        ["fd"] = { "search_files_in_dir", desc = "Search files in dir" },
        ["<esc>"] = {
          function()
            vim.cmd("wincmd p")
          end,
          desc = "Exit to prev window",
        },
        [RightWindowBind] = { "focus_right_win", desc = "Focus right window", mode = { "i", "n" } },
        ["<M-a>"] = { "toggle_no_follow", desc = "Toggle no-follow" },
      },
    },
  },
}
