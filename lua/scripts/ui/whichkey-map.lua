-- Enhanced map function that handles both vim keymaps and which-key
local M = {}
local has_wk, wk = pcall(require, "which-key")
M.map = function(mode, lhs, rhs, options)
  options = options or {}

  local icon = options.icon
  local vim_options = vim.tbl_deep_extend("force", {}, options)
  vim_options.icon = nil -- Remove icon from vim keymap options

  vim.keymap.set(mode, lhs, rhs, vim_options)

  if has_wk and options.icon then
    local wk_spec = {
      lhs,
      rhs,
      desc = options.desc,
      icon = icon,
      mode = mode,
    }

    wk.add({ wk_spec })
  end
end
return M
