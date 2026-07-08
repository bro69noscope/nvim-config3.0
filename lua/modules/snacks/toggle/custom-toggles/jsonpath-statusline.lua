local M = {}

local jsonpath_only = false

M.jsonpath_statusline_toggle = Snacks.toggle.new({
  name = "JsonPath statusline",
  get = function()
    return jsonpath_only
  end,
  set = function(state)
    jsonpath_only = state
    vim.cmd("redrawstatus")
  end,
})

function M.enabled()
  -- only used in diff mode
  return jsonpath_only and vim.wo.diff
end

return M
