local M = {}

local function notify(msg, level)
  vim.notify(msg, level, { title = "GitUnstage" })
end

-- Run git in the buffer's directory (or the cwd if the buffer has no file)
local function git(args, cb)
  local dir = vim.fn.expand("%:p:h")
  if dir == "" or vim.fn.isdirectory(dir) == 0 then
    dir = vim.uv.cwd()
  end

  vim.system(vim.list_extend({ "git" }, args), { cwd = dir, text = true }, vim.schedule_wrap(cb))
end

local function report(r, ok_msg)
  if r.code ~= 0 then
    return notify(vim.trim(r.stderr), vim.log.levels.ERROR)
  end
  notify(ok_msg, vim.log.levels.INFO)
end

-- Remove all staged changes of the current buffer's file from the index
function M.unstage_file()
  local file = vim.fn.expand("%:p")
  if file == "" then
    return notify("Buffer has no file", vim.log.levels.WARN)
  end

  git({ "restore", "--staged", "--", file }, function(r)
    report(r, "Unstaged " .. vim.fn.expand("%:t"))
  end)
end

-- Remove all staged changes from the index (working tree stays the same)
function M.unstage_all()
  git({ "reset", "--quiet" }, function(r)
    report(r, "Unstaged all")
  end)
end

return M
