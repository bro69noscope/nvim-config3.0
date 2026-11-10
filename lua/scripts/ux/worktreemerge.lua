local M = {}

local TITLE = "WorktreeMerge"

---@class Worktree
---@field path string
---@field branch string? nil when the worktree has a detached HEAD

--- Run git async; cb runs on the main loop once git exits.
---@param args string[]
---@param cwd string
---@param cb fun(r: vim.SystemCompleted)
---@param env? table<string, string> extra environment variables for this git call
local function git(args, cwd, cb, env)
  vim.system(
    vim.list_extend({ "git" }, args),
    { cwd = cwd, text = true, env = env },
    vim.schedule_wrap(cb)
  )
end

---@param cwd string
---@param cb fun(sha: string?, err: string?) sha nil + err nil = nothing to snapshot
local function snapshot(cwd, cb)
  local idx = vim.fn.tempname()
  local env = { GIT_INDEX_FILE = idx }
  local function done(sha, err)
    os.remove(idx)
    cb(sha, err)
  end
  local function fail(r)
    done(nil, vim.trim(r.stderr or ""))
  end
  git({ "read-tree", "HEAD" }, cwd, function(a)
    if a.code ~= 0 then
      return fail(a)
    end
    git({ "add", "-A" }, cwd, function(b)
      if b.code ~= 0 then
        return fail(b)
      end
      git({ "write-tree" }, cwd, function(c)
        if c.code ~= 0 then
          return fail(c)
        end
        local tree = vim.trim(c.stdout)
        git({ "rev-parse", "HEAD^{tree}" }, cwd, function(d)
          if d.code ~= 0 then
            return fail(d)
          end
          if vim.trim(d.stdout) == tree then
            return done()
          end
          git(
            { "commit-tree", tree, "-p", "HEAD", "-m", "worktreemerge snapshot" },
            cwd,
            function(e)
              if e.code ~= 0 then
                return fail(e)
              end
              done(vim.trim(e.stdout))
            end
          )
        end)
      end, env)
    end, env)
  end, env)
end

---@param msg string
---@param level? integer vim.log.levels.*, defaults to INFO
local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = TITLE })
end

--- Parse `git worktree list --porcelain`; the first entry is always the main checkout.
---@param out string
---@return Worktree[]
local function parse(out)
  local list, cur = {}, nil
  for line in out:gmatch("[^\r\n]+") do
    local p = line:match("^worktree (.+)$")
    if p then
      cur = { path = p }
      table.insert(list, cur)
    elseif cur then
      local b = line:match("^branch refs/heads/(.+)$")
      if b then
        cur.branch = b
      end
    end
  end
  return list
end

---@param wt Worktree
---@param main Worktree
local function is_llm_path(wt, main)
  return wt ~= main and wt.path:find("/.claude/worktrees/", 1, true) ~= nil
end

-- worktrees owned by the LLM: linked (not main), on a branch, under .claude/worktrees/
---@param list Worktree[]
---@param main Worktree
---@return Worktree[]
local function llm_worktrees(list, main)
  return vim.tbl_filter(function(wt)
    return wt.branch and is_llm_path(wt, main)
  end, list)
end

-- LLM worktrees with a detached HEAD (checkout <sha>, mid-rebase, bisect...) have no
-- branch, so llm_worktrees skips them; say so instead of failing silently
---@param list Worktree[]
---@param main Worktree
local function warn_detached(list, main)
  for _, wt in ipairs(list) do
    if not wt.branch and is_llm_path(wt, main) then
      notify(
        "Skipping " .. wt.path .. ": detached HEAD (mid-rebase, or checked out a commit/tag)",
        vim.log.levels.WARN
      )
    end
  end
end

--- List worktrees, pick the LLM one (asks when there are several) and hand main and it to cb.
---@param prompt string
---@param cb fun(main: Worktree, wt: Worktree)
local function pick_llm_worktree(prompt, cb)
  local dir = vim.uv.cwd()
  if not dir then
    return notify("No working directory", vim.log.levels.ERROR)
  end
  git({ "worktree", "list", "--porcelain" }, dir, function(w)
    if w.code ~= 0 then
      return notify("Not a git repo", vim.log.levels.ERROR)
    end
    local list = parse(w.stdout)
    local main = list[1]
    warn_detached(list, main)
    local llm_wts = llm_worktrees(list, main)
    if #llm_wts == 0 then
      return notify("No LLM worktrees", vim.log.levels.WARN)
    end
    if #llm_wts == 1 then
      return cb(main, llm_wts[1])
    end
    vim.ui.select(llm_wts, {
      prompt = prompt,
      format_item = function(wt)
        return wt.branch .. "  (" .. wt.path .. ")"
      end,
    }, function(choice)
      if choice then
        cb(main, choice)
      end
    end)
  end)
end

---@param path string
---@return string?
local function read_file(path)
  local f = io.open(path, "rb")
  if not f then
    return nil
  end
  local s = f:read("*a")
  f:close()
  return s
end

---@param path string
---@param s string
local function write_file(path, s)
  local f = assert(io.open(path, "wb"))
  f:write(s)
  f:close()
end

---@class DiffHunk
---@field head string the "@@ -a,b +c,d @@" line, newline included
---@field body string[] the hunk's lines, newlines included
---@field stage? boolean set when the hunk is missing from the other worktree

---@class DiffFile
---@field header string "diff --git" line up to the first hunk
---@field hunks DiffHunk[]

--- Split raw `git diff` output into files and hunks. Lines keep their line endings so a patch
--- rebuilt from them is byte-identical.
---@param text string
---@return DiffFile[]
local function parse_diff(text)
  local files, file, hunk = {}, nil, nil
  for line in text:gmatch("[^\n]*\n") do
    if line:find("^diff %-%-git ") then
      file = { header = line, hunks = {} }
      hunk = nil
      table.insert(files, file)
    elseif file and line:find("^@@ ") then
      hunk = { head = line, body = {} }
      table.insert(file.hunks, hunk)
    elseif hunk then
      table.insert(hunk.body, line)
    elseif file then
      file.header = file.header .. line
    end
  end
  return files
end

--- Rewrite a hunk header's new-side start so it fits a patch where some earlier hunks of the
--- same file were left out.
---@param head string
---@param delta integer
---@return string head
---@return integer delta
local function renumber(head, delta)
  local a, b, _, d, rest = head:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@(.*)$")
  a = tonumber(a)
  b = b == "" and 1 or tonumber(b)
  d = d == "" and 1 or tonumber(d)
  -- git counts the new start from the line before when a side is empty
  local adj = (b == 0 and 1) or (d == 0 and -1) or 0
  local new_start = a + adj + delta
  return ("@@ -%d,%d +%d,%d @@%s"):format(a, b, new_start, d, rest), delta + d - b
end

function M.pull_from_llm_worktree()
  local dir = vim.uv.cwd()
  if not dir then
    return notify("No working directory", vim.log.levels.ERROR)
  end
  git({ "worktree", "list", "--porcelain" }, dir, function(w)
    if w.code ~= 0 then
      return notify("Not a git repo:" .. dir, vim.log.levels.ERROR)
    end
    local list = parse(w.stdout)
    local main = list[1]
    warn_detached(list, main)
    local llm_wts = llm_worktrees(list, main)
    if #llm_wts == 0 then
      return notify("No LLM worktrees", vim.log.levels.WARN)
    end

    local function run(wt)
      snapshot(wt.path, function(sha, err)
        if err then
          notify("Snapshot failed, merging committed work only:\n" .. err, vim.log.levels.WARN)
        end
        local ref = sha or wt.branch
        notify(
          ("Squash-merging %s%s into main..."):format(wt.branch, sha and " + uncommitted" or "")
        )
        git({ "merge", "--squash", "--autostash", ref }, main.path, function(r)
          local out = vim.trim((r.stdout or "") .. "\n" .. (r.stderr or ""))
          if r.code == 0 then
            git({ "diff", "--name-only", "--diff-filter=U" }, main.path, function(u)
              local unmerged = vim.trim(u.stdout or "")
              if unmerged ~= "" then
                notify(
                  "Merged, but conflicts remain (resolve with git tooling, then `git reset`):\n"
                    .. unmerged,
                  vim.log.levels.WARN
                )
                return vim.cmd("checktime")
              end
              git({ "reset", "-q" }, main.path, function()
                notify("Merged as unstaged changes.\n" .. out)
                vim.cmd("checktime")
              end)
            end)
          else
            git({ "diff", "--name-only", "--diff-filter=U" }, main.path, function(u)
              local unmerged = vim.trim(u.stdout or "")
              if unmerged ~= "" then
                notify(
                  "Conflicts (resolve with git tooling, then `git reset`):\n" .. unmerged,
                  vim.log.levels.WARN
                )
              else
                notify("Merge not applied:\n" .. out, vim.log.levels.ERROR)
              end
              vim.cmd("checktime")
            end)
          end
        end)
      end)
    end

    if #llm_wts == 1 then
      return run(llm_wts[1])
    end

    vim.ui.select(llm_wts, {
      prompt = "Merge worktree into main (unstaged)",
      format_item = function(wt)
        return wt.branch .. "  (" .. wt.path .. ")"
      end,
    }, function(choice)
      if choice then
        run(choice)
      end
    end)
  end)
end

function M.overwrite_llm_worktree()
  local dir = vim.uv.cwd()
  if not dir then
    return notify("No working directory", vim.log.levels.ERROR)
  end
  git({ "worktree", "list", "--porcelain" }, dir, function(w)
    if w.code ~= 0 then
      return notify("Not a git repo", vim.log.levels.ERROR)
    end
    local list = parse(w.stdout)
    local main = list[1]
    if not main.branch then
      return notify("Main has detached HEAD", vim.log.levels.ERROR)
    end
    warn_detached(list, main)
    local llm_wts = llm_worktrees(list, main)
    if #llm_wts == 0 then
      return notify("No LLM worktrees", vim.log.levels.WARN)
    end

    local function run(wt)
      local function backup_and_reset(cb)
        snapshot(wt.path, function(sha, err)
          if err then
            return notify(
              "Could not snapshot the LLM's edits in the worktree, nothing changed:\n" .. err,
              vim.log.levels.ERROR
            )
          end
          local function reset()
            git({ "reset", "--hard" }, wt.path, function(r)
              if r.code ~= 0 then
                return notify(
                  "reset --hard failed:\n" .. vim.trim(r.stderr or ""),
                  vim.log.levels.ERROR
                )
              end
              cb()
            end)
          end
          if not sha then
            return reset()
          end
          local ref = "refs/wt-backup/" .. os.date("%Y%m%d-%H%M%S")
          git({ "update-ref", ref, sha }, wt.path, function(u)
            if u.code ~= 0 then
              return notify(
                "Could not back up the LLM's uncommitted edits in the worktree, nothing changed:\n"
                  .. vim.trim(u.stderr or ""),
                vim.log.levels.ERROR
              )
            end
            notify(
              "The LLM's uncommitted edits in the worktree saved as "
                .. ref
                .. " (restore: git checkout "
                .. ref
                .. " -- .)"
            )
            reset()
          end)
        end)
      end

      local function merge_ref(ref, label, cb)
        git({ "merge", "--no-edit", "-X", "theirs", ref }, wt.path, function(r)
          local out = vim.trim(r.stdout .. "\n" .. r.stderr)
          if r.code ~= 0 then
            return git({ "merge", "--abort" }, wt.path, function()
              notify(label .. " failed, merge aborted:\n" .. out, vim.log.levels.ERROR)
            end)
          end
          notify(label .. ": " .. out)
          if cb then
            cb()
          end
        end)
      end

      local function do_merge()
        notify(("Overwriting %s with %s (main wins)..."):format(wt.branch, main.branch))
        backup_and_reset(function()
          merge_ref(main.branch, "committed", function()
            snapshot(main.path, function(sha, err)
              if err then
                return notify("Could not snapshot main's edits:\n" .. err, vim.log.levels.ERROR)
              end
              if not sha then
                return notify("No uncommitted edits in main")
              end
              merge_ref(sha, "uncommitted snapshot")
            end)
          end)
        end)
      end

      if vim.uv.fs_stat(wt.path .. "/.git") then
        return do_merge()
      end

      notify("Worktree dir missing, recreating " .. wt.path, vim.log.levels.WARN)
      git({ "worktree", "prune" }, main.path, function()
        git({ "worktree", "add", wt.path, wt.branch }, main.path, function(a)
          if a.code ~= 0 then
            return notify(vim.trim(a.stderr), vim.log.levels.ERROR)
          end
          do_merge()
        end)
      end)
    end

    if #llm_wts == 1 then
      return run(llm_wts[1])
    end
    vim.ui.select(llm_wts, {
      prompt = "Sync " .. main.branch .. " into",
      format_item = function(wt)
        return wt.branch .. "  (" .. wt.path .. ")"
      end,
    }, function(choice)
      if choice then
        run(choice)
      end
    end)
  end)
end

-- Stage, in main, every hunk of your unstaged changes that the LLM worktree does not have.
-- A hunk counts as "in the worktree" when its reverse applies cleanly there (the worktree's
-- files already contain the added lines and lack the removed ones). Shared hunks stay unstaged.
function M.stage_unshared_hunks()
  pick_llm_worktree("Stage hunks missing from", function(main, wt)
    if not vim.uv.fs_stat(wt.path .. "/.git") then
      return notify("Worktree dir missing: " .. wt.path, vim.log.levels.ERROR)
    end
    local diff_file = vim.fn.tempname()
    -- --output keeps git from going through the text-mode pipe, which would eat any \r
    git(
      { "diff", "--no-color", "--no-ext-diff", "--no-textconv", "--output=" .. diff_file },
      main.path,
      function(d)
        local text = read_file(diff_file) or ""
        os.remove(diff_file)
        if d.code ~= 0 then
          return notify("git diff failed:\n" .. vim.trim(d.stderr), vim.log.levels.ERROR)
        end

        local files = parse_diff(text)
        ---@type { file: DiffFile, hunk: DiffHunk }[]
        local tasks = {}
        for _, f in ipairs(files) do
          for _, h in ipairs(f.hunks) do
            table.insert(tasks, { file = f, hunk = h })
          end
        end
        if #tasks == 0 then
          return notify("No unstaged hunks in main")
        end

        local function stage()
          local parts, staged, nfiles = {}, 0, 0
          for _, f in ipairs(files) do
            local delta, kept = 0, {}
            for _, h in ipairs(f.hunks) do
              if h.stage then
                local head
                head, delta = renumber(h.head, delta)
                table.insert(kept, head .. table.concat(h.body))
                staged = staged + 1
              end
            end
            if #kept > 0 then
              nfiles = nfiles + 1
              table.insert(parts, f.header .. table.concat(kept))
            end
          end
          if staged == 0 then
            return notify(
              ("Nothing to stage: all %d unstaged hunk(s) are already in %s"):format(
                #tasks,
                wt.branch
              )
            )
          end
          local patch = vim.fn.tempname()
          write_file(patch, table.concat(parts))
          git({ "apply", "--cached", patch }, main.path, function(r)
            os.remove(patch)
            if r.code ~= 0 then
              return notify(
                "git apply --cached failed, nothing staged:\n" .. vim.trim(r.stderr),
                vim.log.levels.ERROR
              )
            end
            notify(
              ("Staged %d of %d hunk(s) in %d file(s); %d already in %s stay unstaged"):format(
                staged,
                #tasks,
                nfiles,
                #tasks - staged,
                wt.branch
              )
            )
          end)
        end

        -- one hunk at a time: does its reverse apply to the worktree's files?
        local function check(i)
          local t = tasks[i]
          if not t then
            return stage()
          end
          local p = vim.fn.tempname()
          write_file(p, t.file.header .. t.hunk.head .. table.concat(t.hunk.body))
          git({ "apply", "--reverse", "--check", "--ignore-whitespace", p }, wt.path, function(r)
            os.remove(p)
            t.hunk.stage = r.code ~= 0
            check(i + 1)
          end)
        end
        check(1)
      end
    )
  end)
end

return M
