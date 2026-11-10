local M = {}

local TITLE = "WorktreeJump"

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = TITLE })
end

-- parse `git worktree list --porcelain` into { {path=, branch=, head=}, ... }
local function list_worktrees(cwd)
  local r = vim
    .system({ "git", "worktree", "list", "--porcelain" }, { cwd = cwd, text = true })
    :wait()
  if r.code ~= 0 then
    return nil
  end
  local list, cur = {}, nil
  for line in (r.stdout or ""):gmatch("[^\r\n]+") do
    local p = line:match("^worktree (.+)$")
    if p then
      cur = { path = vim.fs.normalize(p) }
      table.insert(list, cur)
    elseif cur then
      cur.branch = line:match("^branch refs/heads/(.+)$") or cur.branch
      cur.head = line:match("^HEAD (%x+)$") or cur.head
    end
  end
  return list
end

local function label(wt)
  local name = wt.branch or ("detached @ " .. (wt.head or "?"):sub(1, 7))
  return name .. "  (" .. wt.path .. ")"
end

local function open(target, diff)
  local pos = vim.api.nvim_win_get_cursor(0)
  local cmd = (diff and "vert diffsplit " or "edit ") .. vim.fn.fnameescape(target)
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    return notify(tostring(err), vim.log.levels.ERROR)
  end
  pcall(vim.api.nvim_win_set_cursor, 0, pos) -- keep the same line
end

--- Open the current file's counterpart in another worktree.
--- opts.diff: open it as a live :vert diffsplit (uncommitted state included) instead of :edit
---@param opts? { diff?: boolean }
function M.jump(opts)
  local diff = opts and opts.diff
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return notify("Buffer has no file", vim.log.levels.WARN)
  end
  file = vim.fs.normalize(file)

  local wts = list_worktrees(vim.fs.dirname(file))
  if not wts then
    return notify("Not a git repo", vim.log.levels.ERROR)
  end

  -- current worktree = the one whose path is the LONGEST prefix of the file
  -- (claude worktrees live inside main, so main's path is a prefix of theirs too).
  -- Windows paths are case-insensitive, so compare lowercased.
  local fkey, current = file:lower(), nil
  for _, wt in ipairs(wts) do
    local k = wt.path:lower()
    if fkey:sub(1, #k + 1) == k .. "/" and (not current or #k > #current.path) then
      current = wt
    end
  end
  if not current then
    return notify("File is not inside a known worktree", vim.log.levels.WARN)
  end
  local rel = file:sub(#current.path + 2)

  -- list EVERY other worktree, including ones where the file doesn't exist, so the picker
  -- always shows them; choosing one without the file reports an error instead of opening
  -- an empty buffer
  local targets = {}
  for _, wt in ipairs(wts) do
    if wt ~= current then
      local candidate = wt.path .. "/" .. rel
      table.insert(
        targets,
        { wt = wt, file = candidate, exists = vim.uv.fs_stat(candidate) ~= nil }
      )
    end
  end
  if #targets == 0 then
    return notify("No other worktrees", vim.log.levels.WARN)
  end

  local function go(t)
    if not t.exists then
      return notify(("%s does not exist in %s"):format(rel, label(t.wt)), vim.log.levels.ERROR)
    end
    open(t.file, diff)
  end

  if #targets == 1 then
    return go(targets[1])
  end

  vim.ui.select(targets, {
    prompt = (diff and "Diff " or "Jump to ") .. rel .. " in",
    format_item = function(t)
      return label(t.wt) .. (t.exists and "" or "  [file missing]")
    end,
  }, function(choice)
    if choice then
      go(choice)
    end
  end)
end

return M
