local M = {}

-- Function to get the symbol under cursor
local function get_symbol_under_cursor()
  return vim.fn.expand("<cword>")
end

-- Function to find the import statement for the symbol
local function find_import_for_symbol(symbol)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for i, line in ipairs(lines) do
    if line:match("from%s+[%w%.]+%s+import.*" .. symbol) then
      return line:gsub("^%s+", ""):gsub("%s+$", "")
    end
  end

  return nil
end

-- Generate ast-grep rules for refactoring a specific symbol
function M.generate_symbol_refactor_template(symbol, old_module)
  return string.format(
    [[id: replace-%s-solo-import
language: python
rule:
  pattern: from %s import %s
fix: from NEW_MODULE_PLACEHOLDER import %s
---
id: replace-%s-with-others
language: python
rule:
  pattern: from %s import $$$BEFORE, %s, $$$AFTER
fix: |
  from %s import $$$BEFORE, $$$AFTER
  from NEW_MODULE_PLACEHOLDER import %s
---
id: replace-%s-multiline-solo
language: python
rule:
  pattern: |
    from %s import (
        %s
    )
fix: |
    from NEW_MODULE_PLACEHOLDER import (
        %s
    )
---
id: replace-%s-multiline-with-others
language: python
rule:
  pattern: |
    from %s import (
        $$$BEFORE,
        %s,
        $$$AFTER
    )
fix: |
    from %s import (
        $$$BEFORE,
        $$$AFTER
    )
    from NEW_MODULE_PLACEHOLDER import (
        %s
    )
]],
    symbol:lower(),
    old_module,
    symbol,
    symbol,
    symbol:lower(),
    old_module,
    symbol,
    old_module,
    symbol,
    symbol:lower(),
    old_module,
    symbol,
    symbol,
    symbol:lower(),
    old_module,
    symbol,
    old_module,
    symbol
  )
end

-- Main function - returns template based on symbol under cursor
function M.generate_template_for_symbol()
  local symbol = get_symbol_under_cursor()

  if not symbol or symbol == "" then
    vim.notify("No symbol under cursor", vim.log.levels.ERROR)
    return nil
  end

  local import_line = find_import_for_symbol(symbol)

  if not import_line then
    vim.notify("Could not find import statement for: " .. symbol, vim.log.levels.ERROR)
    return nil
  end

  -- Extract the old module path
  local old_module = import_line:match("from%s+([%w%.]+)%s+import")

  if not old_module then
    vim.notify("Could not parse module path from import", vim.log.levels.ERROR)
    return nil
  end

  vim.notify(
    string.format("Generating rules for %s from %s", symbol, old_module),
    vim.log.levels.INFO
  )

  return M.generate_symbol_refactor_template(symbol, old_module)
end

return M
