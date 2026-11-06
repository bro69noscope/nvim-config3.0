local M = {}

-- Replace all tags in a grapple scope (nil = current scope) with the picker's
-- selected files (fallback: current item).
M.grapple_replace = function(picker, scope)
  local sel = picker:selected({ fallback = true })
  local paths = {}

  for _, item in ipairs(sel) do
    local path = item.file and Snacks.picker.util.path(item)
    if path and not vim.tbl_contains(paths, path) then
      paths[#paths + 1] = path
    end
  end

  if #paths == 0 then
    return
  end

  local ok, grapple = pcall(require, "grapple")
  if not ok then
    vim.notify("Grapple not available", vim.log.levels.WARN)
    return
  end

  picker:close()
  grapple.reset({ scope = scope })
  for _, path in ipairs(paths) do
    grapple.tag({ path = path, scope = scope })
  end

  vim.notify(("Grapple: tagged %d file(s)"):format(#paths))
end

return M
