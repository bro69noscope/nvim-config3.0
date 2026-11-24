local M = {}
-- NOTE: wezterm kitty graphics is not working super well rn:
-- https://github.com/folke/snacks.nvim/issues/2165
-- We dont allow opening images directly in nvim with the picker for now.

local image_exts = { png = true, jpg = true, jpeg = true, gif = true, webp = true, bmp = true }

--- Open the item with the system viewer if it is an image file.
---@return boolean opened
function M.try_open(item)
  if item and item.file and image_exts[vim.fn.fnamemodify(item.file, ":e"):lower()] then
    vim.ui.open(item.file)
    return true
  end
  return false
end

return M
