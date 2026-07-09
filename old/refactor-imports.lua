local M = {}

-- Normalize path separators to forward slashes
local function normalize_separators(path)
  return path:gsub("\\", "/")
end

-- Normalize path to handle __init__.py and convert to dotted notation
local function normalize_path(relative_path, is_directory)
  local normalized = normalize_separators(relative_path)

  if is_directory then
    return normalized:gsub("/", ".")
  else
    local without_ext = normalized:gsub("%.py$", "")
    if without_ext:match("/__init__$") then
      without_ext = without_ext:gsub("/__init__$", "")
    end
    return without_ext:gsub("/", ".")
  end
end

local function generate_absolute_template(relative_path, is_directory)
  local dotted_path = normalize_path(relative_path, is_directory)
  local parent_path = dotted_path:match("(.+)%.[^%.]+$") or ""
  local replacement_path = parent_path .. ".GRUGRENAME"
  if is_directory then
    local package_template = require("lang.python.astgrep-rules.templates.package")
    -- Directory template with explicit exclusions to avoid duplicates
    return string.format(
      package_template,
      -- id: package
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: package-as
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: from-package
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: from-package-as
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: submodules
      dotted_path,
      replacement_path,
      -- id: submodules-as
      dotted_path,
      replacement_path,
      -- id: from-submodules
      dotted_path,
      replacement_path,
      -- id: from-submodules-as
      dotted_path,
      replacement_path
    )
  else
    local module_template = require("lang.python.astgrep-rules.templates.module")
    local module_name = dotted_path:match("%.([^%.]+)$") or dotted_path
    -- File template
    return string.format(
      module_template,
      -- id: module
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: module-as
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: from-module
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: from-module-as
      dotted_path,
      dotted_path,
      replacement_path,
      -- id: parent-import
      parent_path,
      module_name,
      parent_path,
      -- id: parent-import-as
      parent_path,
      module_name,
      parent_path,
      -- id: parent-import-as-parentheses
      parent_path,
      module_name,
      parent_path,
      -- id: parent-import-multiple
      parent_path,
      module_name,
      parent_path
    )
  end
end

local function generate_relative_template_with_scope(relative_path, is_directory)
  if is_directory then
    local dir_name = vim.fn.fnamemodify(relative_path, ":t")
    local parent_dir = vim.fn.fnamemodify(relative_path, ":h")
    local relative_package_template = require("lang.python.astgrep-rules.templates.rel-package")
    return string.format(
      relative_package_template,
      -- id: rel-from-submodule
      dir_name,
      dir_name
    ),
      parent_dir
  else
    local dotted_path = normalize_path(relative_path, false)
    local module_name = dotted_path:match("%.([^%.]+)$") or dotted_path
    local parent_module = dotted_path:match("%.([^%.]+)%.[^%.]+$")
    local parent_dir = vim.fn.fnamemodify(relative_path, ":h")
    local grandparent_dir = vim.fn.fnamemodify(parent_dir, ":h")

    if parent_module then
      local relative_module_template = require("lang.python.astgrep-rules.templates.rel-module")
      return string.format(
        relative_module_template,
        -- id: rel-from
        module_name,
        -- id: rel-from-parent
        parent_module,
        module_name,
        parent_module
      ),
        grandparent_dir
    else
      local relative_module_noparent_template =
        require("lang.python.astgrep-rules.templates.rel-module-noparent")
      return string.format(
        relative_module_noparent_template,
        -- id: rel-from
        module_name,
        module_name
      ),
        parent_dir
    end
  end
end

M.refactor_python_imports = function(relative_path, is_directory)
  vim.cmd("tabnew")
  local empty_buf = vim.api.nvim_get_current_buf()

  -- First search: absolute imports (global scope)
  local absolute_template = generate_absolute_template(relative_path, is_directory)
  require("grug-far").open({
    engine = "astgrep-rules",
    prefills = {
      rules = absolute_template,
      replacement = "",
    },
  })

  -- Second search: relative imports (scoped appropriately)
  local relative_template, search_dir =
    generate_relative_template_with_scope(relative_path, is_directory)

  if relative_template then
    require("grug-far").open({
      engine = "astgrep-rules",
      prefills = {
        rules = relative_template,
        replacement = "",
        paths = search_dir,
      },
    })
  end

  -- Finally, set up a cozy window layout
  vim.api.nvim_buf_delete(empty_buf, { force = true })
  require("scripts.ui.open-file-explorer").open_main_explorer()
  vim.defer_fn(function()
    vim.cmd("wincmd =")
  end, 0)
end

return M
