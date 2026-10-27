local devnull = OnWindows and "2>nul" or "2>/dev/null"

local function cmdline(args)
  local parts = {}
  for _, a in ipairs(args) do
    parts[#parts + 1] = a:find("%s") and ('"' .. a .. '"') or a
  end
  return table.concat(parts, " ") .. " " .. devnull
end

-- starts the process immediately, does not block
local function start(args)
  return io.popen(cmdline(args))
end

local function read(p)
  local lines = {}
  if not p then
    return lines
  end
  for line in p:lines() do
    lines[#lines + 1] = line
  end
  p:close()
  return lines
end

local function status_args(dir)
  return {
    "git",
    "-C",
    dir,
    "-c",
    "core.quotepath=false",
    "status",
    "--porcelain",
    "-uall",
    "--ignore-submodules=all",
  }
end

local function find_submodules(dir, out)
  local f = io.open(dir .. "/.gitmodules", "r")
  if not f then
    return out
  end
  for line in f:lines() do
    local path = line:match("^%s*path%s*=%s*(.-)%s*$")
    if path then
      local full = dir .. "/" .. path
      -- skip uninitialized submodules (no .git file/dir)
      if vim.uv.fs_stat(full .. "/.git") then
        out[#out + 1] = full
        find_submodules(full, out) -- nested submodules
      end
    end
  end
  f:close()
  return out
end

return {
  title = "Git Status (+submodules)",
  format = "git_status",
  preview = "git_status",
  finder = function()
    local root = read(start({ "git", "rev-parse", "--show-toplevel" }))[1]
    if not root then
      return function() end
    end
    return function(cb)
      local dirs = { root }
      find_submodules(root, dirs)

      -- launch all first so they run in parallel
      local procs = {}
      for i, dir in ipairs(dirs) do
        procs[i] = start(status_args(dir))
      end

      for i, dir in ipairs(dirs) do
        for _, l in ipairs(read(procs[i])) do
          local st, f = l:sub(1, 2), l:sub(4):gsub('^"(.*)"$', "%1")
          local full = dir .. "/" .. f
          local stat = vim.uv.fs_stat(full)
          if not (stat and stat.type == "directory") then
            cb({
              text = st .. " " .. full:sub(#root + 2),
              file = f,
              cwd = dir,
              status = st,
            })
          end
        end
      end
    end
  end,
}
