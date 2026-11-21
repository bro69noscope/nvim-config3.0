local M = {}

---@class GitUnstageUndo
---@field dir string directory the unstage ran in (selects the repo and worktree index)
---@field tree string sha of a tree of the index before the unstage (write-tree)
---@field paths string[] pathspecs that the unstage changed

--- Staging from before the last unstage, nil = no unstage to undo
---@type GitUnstageUndo?
local last

local function notify(msg, level)
  vim.notify(msg, level, { title = "GitUnstage" })
end

-- Directory of the buffer's file (or the cwd if the buffer has no file)
local function buf_dir()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" or vim.fn.isdirectory(dir) == 0 then
    dir = vim.uv.cwd()
  end
  return dir
end

local function git(args, dir, cb)
  vim.system(vim.list_extend({ "git" }, args), { cwd = dir, text = true }, vim.schedule_wrap(cb))
end

local function report(r, ok_msg)
  if r.code ~= 0 then
    return notify(vim.trim(r.stderr), vim.log.levels.ERROR)
  end

  notify(ok_msg, vim.log.levels.INFO)
end

-- Keep the index as a tree, then unstage. If git cannot write the tree (for example, during a
-- merge conflict), unstage without an undo.
local function unstage(dir, paths, args, ok_msg)
  git({ "write-tree" }, dir, function(w)
    if w.code == 0 then
      last = { dir = dir, tree = vim.trim(w.stdout), paths = paths }
    else
      last = nil
      notify("Cannot keep the staging, no undo:\n" .. vim.trim(w.stderr), vim.log.levels.WARN)
    end

    git(args, dir, function(r)
      report(r, ok_msg)
    end)
  end)
end

-- Remove all staged changes of the current buffer's file from the index
function M.unstage_file()
  local file = vim.fn.expand("%:p")
  if file == "" then
    return notify("Buffer has no file", vim.log.levels.WARN)
  end

  unstage(
    buf_dir(),
    { file },
    { "restore", "--staged", "--", file },
    "Unstaged " .. vim.fn.expand("%:t")
  )
end

-- Remove all staged changes from the index (working tree stays the same)
function M.unstage_all()
  unstage(buf_dir(), { ":/" }, { "reset", "--quiet" }, "Unstaged all")
end

local function keys_of(fn)
  local leader = vim.fn.keytrans(vim.g.mapleader or "\\")
  for _, m in ipairs(vim.api.nvim_get_keymap("n")) do
    if m.callback == fn then
      local keys = vim.fn.keytrans(m.lhsraw)
      if vim.startswith(keys, leader) then
        keys = "<leader>" .. keys:sub(#leader + 1)
      end
      return keys
    end
  end
end

-- Put the staging of the paths that the last unstage changed back to before that unstage.
-- Staging of other paths stays the same.
function M.restore()
  if not last then
    local keys = vim.tbl_filter(function(k)
      return k ~= nil
    end, { keys_of(M.unstage_file), keys_of(M.unstage_all) })
    local hint = #keys > 0 and ", unstage first with " .. table.concat(keys, " or ") or ""
    return notify("No unstage to undo" .. hint, vim.log.levels.WARN)
  end

  local undo = last
  local args =
    vim.list_extend({ "restore", "--staged", "--source=" .. undo.tree, "--" }, undo.paths)

  git(args, undo.dir, function(r)
    if r.code == 0 then
      last = nil
    end
    report(r, "Restored the staging from before the unstage")
  end)
end

return M
