local path = require("lang.python.grugfar-refactor.imports.path")

local M = {}

---Generate relative-import rules + a scoped search dir.
---Returns: yaml_string|nil, search_dir|nil
function M.generate(relative_path, is_directory)
  if is_directory then
    local dir_name = vim.fn.fnamemodify(relative_path, ":t")
    local parent_dir = vim.fn.fnamemodify(relative_path, ":h")

    local tpl = require("lang.python.grugfar-refactor.imports.templates.rel-package")
    return string.format(
      tpl,
      -- id: rel-from-submodule
      dir_name
    ), parent_dir
  end

  local dotted = path.normalize_path(relative_path, false)
  local module_name = dotted:match("%.([^%.]+)$") or dotted
  local parent_module = dotted:match("%.([^%.]+)%.[^%.]+$")

  local parent_dir = vim.fn.fnamemodify(relative_path, ":h")
  local grandparent_dir = vim.fn.fnamemodify(parent_dir, ":h")

  if parent_module then
    local tpl = require("lang.python.grugfar-refactor.imports.templates.rel-module")
    return string.format(
      tpl,
      -- id: rel-from
      module_name,
      -- id: rel-from-parent
      parent_module,
      module_name,
      parent_module
    ),
      grandparent_dir
  end

  local tpl = require("lang.python.grugfar-refactor.imports.templates.rel-module-noparent")
  return string.format(
    tpl,
    -- id: rel-from
    module_name
  ), parent_dir
end

return M
