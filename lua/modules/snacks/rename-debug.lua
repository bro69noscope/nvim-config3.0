local M = {}

local CTX = "snacks.rename"
local FLAG = "snacks_rename_custom_fs"

---@type fun(from: string, to: string): boolean
local snacks_rename

local function norm(path)
  return (vim.fn.fnamemodify(path, ":p"):gsub("[\\/]+$", ""))
end

---@param from_p string normalized
---@param to_p string normalized
---@return boolean
local function custom_rename(from_p, to_p)
  vim.fn.mkdir(vim.fs.dirname(to_p), "p")
  local ok, err, errname = vim.uv.fs_rename(from_p, to_p)
  Logger.info(
    ("uv.fs_rename ok=%s err=%s errname=%s"):format(
      tostring(ok),
      tostring(err or "-"),
      tostring(errname or "-")
    ),
    CTX
  )

  if not ok then
    Logger.error(("rename failed from=%q to=%q err=%s"):format(from_p, to_p, tostring(err)), CTX)
    Snacks.notify.error(("Failed to rename file: `%s`\n%s"):format(from_p, tostring(err)))
    return false
  end

  local from_buf = vim.fn.bufnr(from_p)
  if from_buf >= 0 then
    local to_buf = vim.fn.bufadd(to_p)
    vim.bo[to_buf].buflisted = true
    for _, win in ipairs(vim.fn.win_findbuf(from_buf)) do
      vim.api.nvim_win_call(win, function()
        vim.cmd("buffer " .. to_buf)
      end)
    end
    vim.api.nvim_buf_delete(from_buf, { force = true })
  end
  return true
end

---@param from string
---@param to string
---@return boolean
function M.rename(from, to)
  local custom = vim.g[FLAG] == true
  local from_p, to_p = norm(from), norm(to)
  Logger.info(
    ("rename attempt impl=%s from=%q to=%q"):format(custom and "custom" or "snacks", from_p, to_p),
    CTX
  )

  local ok
  if custom then
    ok = custom_rename(from_p, to_p)
  else
    ok = snacks_rename(from, to)
  end

  if ok then
    Logger.info("rename succeeded", CTX)
  else
    Logger.error(
      ("rename failed impl=%s from=%q to=%q"):format(custom and "custom" or "snacks", from_p, to_p),
      CTX
    )
  end
  return ok
end

--- Patch snacks.rename so every rename is logged (snacks' own logic stays the default).
function M.setup()
  local ok, rename_mod = pcall(require, "snacks.rename")
  if not ok or snacks_rename then
    return
  end
  snacks_rename = rename_mod._rename
  rename_mod._rename = M.rename
end

return M
