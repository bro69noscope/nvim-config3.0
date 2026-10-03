local M = {}

local launch_picker_with_explorer_return =
  require("modules.snacks.picker.explorer.actions.launch-with-explorer-return")

M.expand_recursive = function(picker, item)
  if not item or not item.file then
    return
  end

  local Tree = require("snacks.explorer.tree")
  local Actions = require("snacks.explorer.actions")

  local path = item.dir and item.file or vim.fn.fnamemodify(item.file, ":h")
  local root = Tree:node(path)

  Tree:walk(root, function(node)
    if node.dir then
      Tree:open(node.path)
      Tree:expand(node)
    end
  end, { all = true })

  Actions.update(picker, { refresh = true })
end

M.open_with_system = function(picker, item)
  if not item then
    return
  end
  vim.ui.open(item.file)
end

M.search_files_in_dir = function(picker, item)
  if not item or not item.file then
    return
  end
  local path
  if vim.fn.isdirectory(item.file) == 1 then
    path = item.file
  else
    path = vim.fn.fnamemodify(item.file, ":h")
  end
  local title = "Search files in: " .. vim.fn.fnamemodify(path, ":~:.")
  local dirs = { path }

  launch_picker_with_explorer_return(Snacks.picker.files, {
    title = title,
    dirs = dirs,
  })
end

M.grep_in_dir = function(picker, item, opts)
  if not item or not item.file then
    return
  end

  local path
  if vim.fn.isdirectory(item.file) == 1 then
    path = item.file
  else
    path = vim.fn.fnamemodify(item.file, ":h")
  end

  local title = "Grep in: " .. vim.fn.fnamemodify(path, ":~:.")
  local dirs = { path }

  local input_grep_globs = require("modules.snacks.picker.actions.input-grep-globs")

  local config = {
    title = title,
    dirs = dirs,
    win = {
      input = {
        keys = require("modules.snacks.picker.keys.setup-picker-keys").setup_grep_input_keys(
          dirs,
          title,
          "grep"
        ),
      },
    },
    actions = {
      grep_globs_input = input_grep_globs.make_action(dirs, title, "grep"),
    },
  }

  if opts and opts.default_grep == true then
    config.finder = "grep"
  end

  launch_picker_with_explorer_return(Snacks.picker.grep, config)
end

M.grug_far_refactor_imports = function(picker, item)
  if not item or not item.file then
    return
  end

  local is_directory = vim.fn.isdirectory(item.file) == 1
  local relative_path = vim.fn.fnamemodify(item.file, ":.")
  local grug_far_astgrep = require("lang.python.grugfar-refactor.imports.init")
  --TODO:WIP

  grug_far_astgrep.grug_refactor_python_imports(relative_path, is_directory)
end

return M
