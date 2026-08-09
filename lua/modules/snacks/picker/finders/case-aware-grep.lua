local M = {}

local MODE_FLAGS = {
  smart = "--smart-case",
  ignore = "--ignore-case",
  sensitive = "--case-sensitive",
}
local ALL_CASE_FLAGS = { "--case-sensitive", "--ignore-case", "--smart-case" }

--- Wraps a grep-like finder to inject the current case-mode flag.
--- @param base_finder function
function M.wrap(base_finder)
  return function(opts, ctx)
    opts.args = vim
      .iter(opts.args or {})
      :filter(function(v)
        return not vim.list_contains(ALL_CASE_FLAGS, v)
      end)
      :totable()

    vim.list_extend(opts.args, { MODE_FLAGS[opts.case_mode or "smart"] })

    return base_finder(opts, ctx)
  end
end

return M
