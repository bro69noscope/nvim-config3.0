local M = {}
local persist_flags = require("modules.snacks.picker.persist-flags")

M.open = function(opts)
  opts = opts or {}
  require("snacks").explorer(vim.tbl_deep_extend("force", {
    hidden = persist_flags.get("explorer", "hidden", false),
    ignored = persist_flags.get("explorer", "ignored", false),
  }, opts))
end

return M
