local M = {}

local function notify(msg, level)
  vim.notify(msg, level, { title = "GitAdd" })
end

local function buf_dir()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" or vim.fn.isdirectory(dir) == 0 then
    dir = vim.uv.cwd()
  end
  return dir
end

local function add(dir, args, ok_msg)
  vim.system(
    vim.list_extend({ "git", "add" }, args),
    { cwd = dir, text = true },
    vim.schedule_wrap(function(r)
      if r.code ~= 0 then
        return notify(vim.trim(r.stderr), vim.log.levels.ERROR)
      end

      notify(ok_msg, vim.log.levels.INFO)
    end)
  )
end

function M.add_file()
  local file = vim.fn.expand("%:p")
  if file == "" then
    return notify("Buffer has no file", vim.log.levels.WARN)
  end

  add(buf_dir(), { "--", file }, "Staged " .. vim.fn.expand("%:t"))
end

function M.add_all()
  add(buf_dir(), { "--all" }, "Staged all")
end

return M
