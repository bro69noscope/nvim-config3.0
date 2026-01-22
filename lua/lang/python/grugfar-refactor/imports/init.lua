local yaml_docs = require("lang.python.grugfar-refactor.imports.yaml_docs")
local absolute_template = require("lang.python.grugfar-refactor.imports.absolute_template")
local relative_template = require("lang.python.grugfar-refactor.imports.relative_template")
local elect = require("lang.python.grugfar-refactor.imports.elect")

local M = {}

local function arrange_layout(empty_buf)
  if vim.api.nvim_buf_is_valid(empty_buf) then
    vim.api.nvim_buf_delete(empty_buf, { force = true })
  end
  require("scripts.ui.open-file-explorer").open_main_explorer()
  vim.defer_fn(function()
    vim.cmd("wincmd =")
  end, 0)
end

function M.grug_refactor_python_imports(relative_path, is_directory, opts)
  opts = opts or {}

  vim.cmd("tabnew")
  local empty_buf = vim.api.nvim_get_current_buf()

  -- Track completion of both elect operations
  local completed = { absolute = false, relative = false }
  local function check_all_done()
    if completed.absolute and completed.relative then
      arrange_layout(empty_buf)
    end
  end

  -- Absolute imports
  local abs_template = absolute_template.generate(relative_path, is_directory)
  if abs_template and abs_template ~= "" then
    local abs_docs = yaml_docs.split_yaml_docs(abs_template)
    elect.elect_rules(abs_docs, {
      type = "absolute",
      notify = true,
      on_complete = function()
        completed.absolute = true
        check_all_done()
      end,
    })
  else
    vim.notify("No absolute import rules generated", vim.log.levels.WARN)
    completed.absolute = true
    check_all_done()
  end

  -- Relative imports
  local rel_template, search_dir = relative_template.generate(relative_path, is_directory)
  if rel_template and rel_template ~= "" then
    local rel_docs = yaml_docs.split_yaml_docs(rel_template)
    elect.elect_rules(rel_docs, {
      type = "relative",
      paths = search_dir,
      notify = true,
      on_complete = function()
        completed.relative = true
        check_all_done()
      end,
    })
  else
    vim.notify("No relative import rules generated", vim.log.levels.WARN)
    completed.relative = true
    check_all_done()
  end
end

return M
