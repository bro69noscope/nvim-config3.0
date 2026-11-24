local M = {}

-- go to next/prev ALLCAPS words in python files
local constant_pattern = [[\<[A-Z][A-Z0-9_]*\>\s*=]]

-- Repeatable with ; and , through repeatable-pairs.
M.next_constant, M.prev_constant = require("config.repeatable-pairs").track_pair(function()
  vim.fn.search(constant_pattern, "")
end, function()
  vim.fn.search(constant_pattern, "b")
end)

return M
