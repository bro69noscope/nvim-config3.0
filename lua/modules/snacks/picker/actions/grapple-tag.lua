local M = {}

---@param path string
---@return integer?
local function first_change_line(path)
  local out = vim.fn.systemlist({
    "git",
    "-C",
    vim.fn.fnamemodify(path, ":h"),
    "diff",
    "HEAD",
    "-U0",
    "--no-color",
    "--",
    path,
  })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  for _, line in ipairs(out) do
    local start = line:match("^@@ %-%d+,?%d* %+(%d+)")
    if start then
      return math.max(tonumber(start), 1)
    end
  end
  return nil
end

---@param switch? boolean also make `scope` the active scope afterwards
---@param at_first_change? boolean put each tag's cursor on its file's first change
M.grapple_replace = function(picker, scope, switch, at_first_change)
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

  if scope and not grapple.app().scope_manager:exists(scope) then
    vim.notify(("Grapple: unknown scope '%s'"):format(scope), vim.log.levels.WARN)
    return
  end

  picker:close()
  grapple.reset({ scope = scope })
  for _, path in ipairs(paths) do
    local line = at_first_change and first_change_line(path) or nil
    grapple.tag({ path = path, scope = scope, cursor = line and { line, 0 } or nil })
  end

  if switch and scope then
    grapple.use_scope(scope, { notify = false })
  end

  vim.notify(("Grapple: tagged %d file(s)"):format(#paths))
end

return M
