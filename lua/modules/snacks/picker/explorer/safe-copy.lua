local M = {}

--- Given a target path, returns the same path if free, otherwise
--- name_1.ext, name_2.ext, ... (suffix inserted before the last extension)
local function next_available_path(path)
  local uv = vim.uv or vim.loop
  if not uv.fs_stat(path) then
    return path
  end

  local dir = vim.fs.dirname(path)
  local base = vim.fs.basename(path)
  local name, ext = base:match("^(.*)%.([^.]+)$")
  if not name then
    name, ext = base, nil
  end

  local count = 1
  local candidate
  repeat
    local suffix = "_" .. count
    local candidate_base = ext and (name .. suffix .. "." .. ext) or (name .. suffix)
    candidate = vim.fs.normalize(dir .. "/" .. candidate_base)
    count = count + 1
  until not uv.fs_stat(candidate)

  return candidate
end

function M.setup()
  local util = require("snacks.picker.util")
  local orig_copy_path = util.copy_path
  util.copy_path = function(from, to)
    return orig_copy_path(from, next_available_path(to))
  end
end

return M
