local M = {}

local function find_up(rel)
  local src = debug.getinfo(1, "S").source:sub(2)
  src = vim.uv.fs_realpath(src) or src

  for dir in vim.fs.parents(src) do
    local p = dir .. "/" .. rel
    if vim.uv.fs_stat(p) then
      return p
    end
  end
end

local paths_file = find_up("shared/wezterm-paths.txt") -- located in dotfiles/ parent repo
local sock_dir = vim.fn.expand("~/.local/share/wezterm")
local excluded_titles = { "[[NVIM-SCRATCH]]", "WezTerm - secondary" }

local function prune_dead_sockets()
  for name in vim.fs.dir(sock_dir) do
    local pid = tonumber(name:match("^gui%-sock%-(%d+)$"))
    if pid then
      local ok, _, errname = vim.uv.kill(pid, 0)
      if ok ~= 0 and errname == "ESRCH" then
        vim.uv.fs_unlink(sock_dir .. "/" .. name)
      end
    end
  end
end

local function wezterm_bin()
  if not paths_file then
    return nil
  end

  if vim.fn.filereadable(paths_file) == 0 then
    return nil
  end

  for _, line in ipairs(vim.fn.readfile(paths_file)) do
    line = vim.trim(line)
    if line ~= "" and line:sub(1, 1) ~= "#" then
      -- list holds wezterm-gui.exe; cli needs wezterm.exe next to it
      local cli = line:gsub("wezterm%-gui%.exe$", "wezterm.exe")
      if vim.uv.fs_stat(cli) then
        return cli
      end
    end
  end
end

local function is_excluded(panes)
  for _, pane in ipairs(panes) do
    for _, field in ipairs({ "title", "tab_title", "window_title" }) do
      local value = pane[field]
      if type(value) ~= "string" then
        value = ""
      end
      for _, needle in ipairs(excluded_titles) do
        if value:find(needle, 1, true) then
          return true
        end
      end
    end
  end
  return false
end

local function main_socket(bin)
  local socks = {}

  for name in vim.fs.dir(sock_dir) do
    local pid = tonumber(name:match("gui%-sock%-(%d+)"))
    if pid then
      local ok, _, errname = vim.uv.kill(pid, 0)
      if ok == 0 or errname == "EPERM" then
        local path = sock_dir .. "/" .. name
        local st = vim.uv.fs_lstat(path)
        table.insert(socks, { path = path, pid = pid, mtime = st and st.mtime.sec or 0 })
      end
    end
  end

  table.sort(socks, function(a, b)
    if a.mtime ~= b.mtime then
      return a.mtime < b.mtime
    end
    return a.pid < b.pid
  end)

  local found
  for _, s in ipairs(socks) do
    local res = vim
      .system(
        { bin, "cli", "list", "--format", "json" },
        { env = { WEZTERM_UNIX_SOCKET = s.path }, text = true, timeout = 1000 }
      )
      :wait()

    local line = ("pid %d: code=%s"):format(s.pid, tostring(res.code))

    if res.code == 0 then
      local ok, panes = pcall(vim.json.decode, res.stdout)
      if ok and type(panes) == "table" then
        local excluded = is_excluded(panes)
        local p = panes[1] or {}
        line = line
          .. (" excluded=%s title=%q tab=%q win=%q"):format(
            tostring(excluded),
            tostring(p.title),
            tostring(p.tab_title),
            tostring(p.window_title)
          )
        if not excluded and not found then
          found = s.path
          break
        end
      else
        line = line .. " json decode failed"
      end
    end
  end

  return found
end

local function spawn_wezterm(cwd)
  prune_dead_sockets()
  local bin = wezterm_bin()
  if not bin then
    vim.notify("no wezterm.exe found", vim.log.levels.ERROR)
    return
  end

  vim.notify("Spawning WezTerm with bin: " .. bin, vim.log.levels.DEBUG)

  local err = {}
  local sock = main_socket(bin)

  vim.fn.jobstart({ bin, "cli", "spawn", "--cwd", cwd }, {
    env = sock and { WEZTERM_UNIX_SOCKET = sock } or nil,
    stderr_buffered = true,
    on_stderr = function(_, data)
      err = data
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.notify(
          "wezterm cli failed (" .. code .. "), starting new window:\n" .. table.concat(err, "\n"),
          vim.log.levels.WARN
        )
        vim.fn.jobstart({ bin, "start", "--cwd", cwd }, { detach = true })
      end
      vim.notify("Opened WezTerm in cwd:\n" .. cwd, vim.log.levels.INFO)
    end,
  })
end

M.new_cwd_wezterm_tab = function()
  spawn_wezterm(vim.fn.getcwd())
end

M.new_cwd_this_file_wezterm_tab = function()
  spawn_wezterm(vim.fn.expand("%:p:h"))
end

return M
