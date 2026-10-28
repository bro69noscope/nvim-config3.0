local M = {}

local CARRY = {
  "glob",
  "dirs",
  "args",
  "exclude",
  "ft",
  "case_mode",
  "and_search",
  "hidden",
  "ignored",
  "win",
}

M.title = function(base, scope)
  if not scope then
    return base
  end
  return base .. " [" .. scope .. "]"
end

M.rescope = function(picker, scope)
  local source = picker.opts.source or "buffers"
  local text = picker.input:get()
  local is_live = picker.opts.live
  local base = picker.opts._base_title or picker._base_title or picker.title
  local filter = type(picker.opts.filter) == "table" and vim.deepcopy(picker.opts.filter) or {}

  local opts = {
    _scope = scope,
    _base_title = base,
    title = M.title(base, scope),
    filter = filter,
  }
  for _, key in ipairs(CARRY) do
    if picker.opts[key] ~= nil then
      opts[key] = vim.deepcopy(picker.opts[key])
    end
  end

  if is_live then
    opts.search = text
  else
    opts.pattern = text
  end

  opts.filter.cwd = scope ~= "all"
  if scope == "git root" then
    opts.cwd = Snacks.git.get_root() or vim.fn.getcwd()
  elseif scope == "cwd" then
    opts.cwd = vim.fn.getcwd()
  end

  picker:close()
  vim.schedule(function()
    Snacks.picker.pick(source, opts)
  end)
end

return M
