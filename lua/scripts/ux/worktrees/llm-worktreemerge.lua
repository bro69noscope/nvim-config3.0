local M = {}

local TITLE = "LlmWorktreeMerge"
local CTX = "llm-worktreemerge"
local notify = require("config.notifylog").bind({ title = TITLE, ctx = CTX })

local UNTRACKED_LIMIT = 2000
local BACKUP_KEEP = 20
local PULLED = "refs/wt-pulled/"
local BACKUP_PREFIX = "refs/wt-backup/"
local BACKUP_NAME = "^" .. vim.pesc(BACKUP_PREFIX) .. "%d%d%d%d%d%d%d%d%-%d%d%d%d%d%d%-%d%d%d$"

---@class Worktree
---@field path string
---@field branch string? nil when the worktree has a detached HEAD
---@field is_main boolean? true for the main checkout (first in `git worktree list`)

local in_flight = 0

---@param args string[]
---@param cwd string
---@param cb fun(r: vim.SystemCompleted)
---@param env? table<string, string> extra environment variables for this git call
---@param stdin? string written to git's standard input
local function git(args, cwd, cb, env, stdin)
  in_flight = in_flight + 1

  ---@param r vim.SystemCompleted
  local function on_exit(r)
    local cb_ok, cb_err = pcall(cb, r)
    in_flight = in_flight - 1
    if not cb_ok then
      error(cb_err, 0)
    end
  end

  local ok, err = pcall(
    vim.system,
    vim.list_extend({ "git" }, args),
    { cwd = cwd, text = true, env = env, stdin = stdin },
    vim.schedule_wrap(on_exit)
  )

  if not ok then
    in_flight = in_flight - 1
    error(err, 0)
  end
end

---@return boolean
local function busy()
  if in_flight == 0 then
    return false
  end
  notify(
    "Another LLM worktree command is still running, try again in a moment",
    vim.log.levels.WARN
  )
  return true
end

--- vim.ui.select that keeps busy() true while the picker is open
---@generic T
---@param items T[]
---@param opts table
---@param cb fun(choice: T?)
local function select(items, opts, cb)
  in_flight = in_flight + 1
  local ok, err = pcall(vim.ui.select, items, opts, function(choice)
    -- cb starts its own git calls first, so the counter stays above 0 across the hand-over
    local cb_ok, cb_err = pcall(cb, choice)
    in_flight = in_flight - 1
    if not cb_ok then
      error(cb_err, 0)
    end
  end)
  if not ok then
    in_flight = in_flight - 1
    error(err, 0)
  end
end

---@param args string[]
---@param cwd string
---@param what string what the call was for, used in the error message
---@param cb fun(out: string)
local function must(args, cwd, what, cb)
  git(args, cwd, function(r)
    if r.code ~= 0 then
      return notify(("%s failed:\n%s"):format(what, vim.trim(r.stderr or "")), vim.log.levels.ERROR)
    end
    cb(vim.trim(r.stdout or ""))
  end)
end

-- Refs are shared by all worktrees, so the ones about a pull name the worktree pulled into
-- (target). Main keeps the plain names, which predate pulling into other worktrees.

--- What the last pull of llm into target brought in, the base of the next pull
---@param target Worktree
---@param llm Worktree
---@return string
local function pulled_ref(target, llm)
  return PULLED .. llm.branch .. (target.is_main and "" or "@" .. target.branch)
end

--- The undo point of target's last pull ("pull"), or the blob listing the files that pull left
--- conflicted, NUL-separated ("conflicts"). One slot per target.
---@param target Worktree
---@param name "pull"|"conflicts"
---@return string
local function undo_ref(target, name)
  return "refs/wt-undo/" .. (target.is_main and "" or "@" .. target.branch .. "/") .. name
end

---@param cwd string
local function prune_backups(cwd)
  local list = { "for-each-ref", "--sort=-refname", "--format=%(refname)", BACKUP_PREFIX }
  git(list, cwd, function(r)
    if r.code ~= 0 then
      return Logger.warn("could not list old backups: " .. vim.trim(r.stderr or ""), CTX)
    end

    local refs = vim.tbl_filter(function(ref)
      return ref:match(BACKUP_NAME) ~= nil
    end, vim.split(r.stdout or "", "\n", { plain = true, trimempty = true }))

    if #refs > BACKUP_KEEP then
      local n = #refs - BACKUP_KEEP
      Logger.debug(("pruning %d old backups (keeping %d)"):format(n, BACKUP_KEEP), CTX)
    end

    for i = BACKUP_KEEP + 1, #refs do
      local old = vim.trim(refs[i])
      git({ "update-ref", "-d", old }, cwd, function(d)
        if d.code ~= 0 then
          local why = vim.trim(d.stderr or "")
          Logger.warn(("could not delete old backup %s: %s"):format(old, why), CTX)
        end
      end)
    end
  end)
end

---@return string
local function backup_ref()
  local sec, usec = vim.uv.gettimeofday()
  return BACKUP_PREFIX .. os.date("%Y%m%d-%H%M%S", sec) .. ("-%03d"):format(math.floor(usec / 1000))
end

---@param cwd string
---@param cb fun(tree: string?, err: string?)
local function working_tree(cwd, cb)
  local idx = vim.fn.tempname()
  local env = { GIT_INDEX_FILE = idx }
  local function done(tree, err)
    os.remove(idx)
    cb(tree, err)
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
        done(vim.trim(c.stdout))
      end, env)
    end, env)
  end, env)
end

---@param cwd string
---@param cb fun(sha: string?, err: string?, tree: string?) sha nil + err nil = nothing to snapshot
local function take_snapshot(cwd, cb)
  working_tree(cwd, function(tree, err)
    if err then
      return cb(nil, err)
    end
    git({ "rev-parse", "HEAD^{tree}" }, cwd, function(d)
      if d.code ~= 0 then
        return cb(nil, vim.trim(d.stderr or ""))
      end
      if vim.trim(d.stdout) == tree then
        return cb(nil, nil, tree)
      end
      git({ "commit-tree", tree, "-p", "HEAD", "-m", "worktreemerge snapshot" }, cwd, function(e)
        if e.code ~= 0 then
          return cb(nil, vim.trim(e.stderr or ""))
        end
        cb(vim.trim(e.stdout), nil, tree)
      end)
    end)
  end)
end

---@param cwd string
---@param cb fun(sha: string?, err: string?, tree: string?) sha nil + err nil = nothing to snapshot
local function snapshot(cwd, cb)
  git({ "ls-files", "--others", "--exclude-standard", "-z" }, cwd, function(u)
    local paths = u.code == 0 and vim.split(u.stdout, "\0", { plain = true, trimempty = true })
      or {}
    if #paths <= UNTRACKED_LIMIT then
      return take_snapshot(cwd, cb)
    end

    local per_dir = {}
    for _, p in ipairs(paths) do
      local top = p:match("^([^/]+)/") or "(top level)"
      per_dir[top] = (per_dir[top] or 0) + 1
    end

    local dirs = vim.tbl_keys(per_dir)
    table.sort(dirs, function(a, b)
      return per_dir[a] > per_dir[b]
    end)

    local top3 = vim.tbl_map(function(d)
      return ("%s (%d)"):format(d, per_dir[d])
    end, vim.list_slice(dirs, 1, 3))

    cb(
      nil,
      (
        "%d untracked files in %s (limit %d). Gitignore them, e.g. in .git/info/exclude, "
        .. "then retry. Biggest: %s"
      ):format(#paths, cwd, UNTRACKED_LIMIT, table.concat(top3, ", "))
    )
  end)
end

---@param cwd string
---@param cb fun(tree: string?, err: string?) tree nil + err nil = nothing staged
local function staged_tree(cwd, cb)
  git({ "write-tree" }, cwd, function(a)
    if a.code ~= 0 then
      return cb(nil, vim.trim(a.stderr or ""))
    end
    local tree = vim.trim(a.stdout)
    git({ "rev-parse", "HEAD^{tree}" }, cwd, function(b)
      if b.code ~= 0 then
        return cb(nil, vim.trim(b.stderr or ""))
      end
      if vim.trim(b.stdout) == tree then
        return cb(nil)
      end
      cb(tree)
    end)
  end)
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
  if list[1] then
    list[1].is_main = true
  end
  return list
end

---@param p string
---@return string
local function norm_path(p)
  p = vim.fs.normalize(p)
  return vim.fn.has("win32") == 1 and p:lower() or p
end

--- The worktree the cwd is in: the longest matching path, since LLM worktrees sit inside main
---@param list Worktree[]
---@param dir string
---@return Worktree?
local function worktree_at(list, dir)
  local d, found = norm_path(dir), nil
  for _, wt in ipairs(list) do
    local p = norm_path(wt.path)
    if (d == p or vim.startswith(d, p .. "/")) and (not found or #wt.path > #found.path) then
      found = wt
    end
  end
  return found
end

--- Run cb with the worktree list and the worktree the cwd is in, the one pulled into
---@param cb fun(list: Worktree[], target: Worktree)
local function with_target(cb)
  local dir = vim.uv.cwd()
  if not dir then
    return notify("No working directory", vim.log.levels.ERROR)
  end

  git({ "worktree", "list", "--porcelain" }, dir, function(w)
    if w.code ~= 0 then
      return notify("Not a git repo: " .. dir, vim.log.levels.ERROR)
    end

    local list = parse(w.stdout)
    local target = worktree_at(list, dir)
    if not target then
      return notify("The cwd is in no worktree of this repo: " .. dir, vim.log.levels.ERROR)
    end

    if not target.is_main and not target.branch then
      return notify(
        target.path .. " has a detached HEAD, check out a branch first",
        vim.log.levels.ERROR
      )
    end

    cb(list, target)
  end)
end

---@param target Worktree
---@return string
local function label(target)
  return target.is_main and "main" or target.branch
end

---@param wt Worktree
---@param main Worktree
local function is_llm_path(wt, main)
  return wt ~= main and wt.path:find("/.claude/worktrees/", 1, true) ~= nil
end

---@param list Worktree[]
---@param main Worktree
---@return Worktree[]
local function llm_worktrees(list, main)
  return vim.tbl_filter(function(wt)
    return wt.branch and is_llm_path(wt, main)
  end, list)
end

-- LLM worktrees with a detached HEAD (checkout <sha>, mid-rebase, bisect...) have no branch
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

---@param prompt string picker prompt, %s = the target's label
---@param cb fun(target: Worktree, llm: Worktree)
local function pick_llm_worktree(prompt, cb)
  with_target(function(list, target)
    local main = list[1]
    warn_detached(list, main)
    -- a target that is itself an LLM worktree can't pair with itself
    local llm_wts = vim.tbl_filter(function(llm)
      return llm ~= target
    end, llm_worktrees(list, main))
    if #llm_wts == 0 then
      return notify("No other LLM worktrees", vim.log.levels.WARN)
    end
    if #llm_wts == 1 then
      return cb(target, llm_wts[1])
    end

    select(llm_wts, {
      prompt = prompt:format(label(target)),
      format_item = function(llm)
        return llm.branch .. "  (" .. llm.path .. ")"
      end,
    }, function(choice)
      if choice then
        cb(target, choice)
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

---@param header string
---@return string?
local function diff_path(header)
  local a, b = header:match("^diff %-%-git a/([^\n]+) b/([^\n]+)\n")
  if a and a == b then
    return a
  end
end

---@param hunk DiffHunk
---@return number lo
---@return number hi
local function changed_span(hunk)
  local c, d = hunk.head:match("^@@ %-%d+,?%d* %+(%d+),?(%d*) @@")
  local n = tonumber(c)
  if d == "0" then
    n = n + 1 -- pure deletion: git gives the line before the gap, we want the line after
  end
  local lo, hi = math.huge, -math.huge
  for _, line in ipairs(hunk.body) do
    local kind = line:sub(1, 1)
    if kind == " " then
      n = n + 1
    elseif kind == "+" then
      lo, hi = math.min(lo, n - 0.5), math.max(hi, n + 0.5)
      n = n + 1
    elseif kind == "-" then
      lo, hi = math.min(lo, n - 0.5), math.max(hi, n - 0.5)
    end
  end
  return lo, hi
end

---@param text string
---@return number[][] regions each { lo, hi }
local function diff_regions(text)
  local regions = {}
  for a_str, b_str in text:gmatch("\n@@ %-(%d+),?(%d*) ") do
    local a = tonumber(a_str)
    local b = b_str == "" and 1 or tonumber(b_str)
    if b > 0 then
      table.insert(regions, { a - 0.5, a + b - 0.5 })
    else
      -- b == 0: lines were inserted after old line a
      table.insert(regions, { a + 0.5, a + 0.5 })
    end
  end
  return regions
end

---@return boolean
local function overlaps(lo1, hi1, lo2, hi2)
  if lo1 == hi1 and lo2 == hi2 then
    return lo1 == lo2
  end
  return lo1 < hi2 and lo2 < hi1
end

---@param main Worktree
---@param staged string? tree from staged_tree
---@param cb fun(r: vim.SystemCompleted)
local function restore_staging(target, staged, cb)
  local reset = staged and { "read-tree", staged } or { "reset", "-q" }
  git(reset, target.path, cb)
end

---@param target Worktree
---@param llm Worktree
---@param tree string target's files on disk, from working_tree
---@param staged string? target's staging, from staged_tree
---@param cb fun()
local function save_undo(target, llm, tree, staged, cb)
  local what = "Saving the undo point (nothing changed yet)"
  git({ "rev-parse", "--verify", "-q", pulled_ref(target, llm) }, target.path, function(p)
    -- what undo_pull resets the pulled mark to, "none" = first pull
    local msg = ("worktreemerge undo point\n\nbranch %s\npulled %s"):format(
      llm.branch,
      p.code == 0 and vim.trim(p.stdout) or "none"
    )
    -- parents: HEAD, then the staging if any (a parent must be a commit, so it gets wrapped)
    local function save(parents)
      local args = vim.list_extend({ "commit-tree", tree, "-p", "HEAD" }, parents)
      vim.list_extend(args, { "-m", msg })
      must(args, target.path, what, function(point)
        must({ "update-ref", undo_ref(target, "pull"), point }, target.path, what, function()
          must({ "update-ref", "-d", undo_ref(target, "conflicts") }, target.path, what, function()
            cb()
          end)
        end)
      end)
    end

    if not staged then
      return save({})
    end

    local wrap = { "commit-tree", staged, "-p", "HEAD", "-m", "worktreemerge staging" }
    must(wrap, target.path, what, function(s)
      save({ "-p", s })
    end)
  end)
end

---@param target Worktree
---@param llm Worktree
---@param sha string? worktree snapshot this pull brought into target. nil = its HEAD
local function record_pulled(target, llm, sha)
  local function save(commit)
    git({ "update-ref", pulled_ref(target, llm), commit }, target.path, function(r)
      if r.code ~= 0 then
        Logger.warn("could not record the pulled state: " .. vim.trim(r.stderr or ""), CTX)
      end
    end)
  end

  if sha then
    return save(sha)
  end

  git({ "rev-parse", llm.branch }, target.path, function(r)
    if r.code ~= 0 then
      return Logger.warn("could not record the pulled state: " .. vim.trim(r.stderr or ""), CTX)
    end
    save(vim.trim(r.stdout))
  end)
end

--- Merge the worktree into target (the cwd's worktree) starting from the previous pull: only what
--- changed in the worktree since then comes in, and target's own edits stay.
---@param target Worktree
---@param llm Worktree
---@param base string commit of the previous pull
---@param sha string? snapshot commit of the worktree now; nil = its HEAD
---@param staged string? target's staged state, put back afterwards
---@param hint string
local function pull_from_base(target, llm, base, sha, staged, hint)
  snapshot(target.path, function(msha, merr, mtree)
    if merr then
      return notify(
        ("Could not snapshot %s, nothing changed:\n"):format(label(target)) .. merr,
        vim.log.levels.ERROR
      )
    end

    local function merge()
      local args = {
        "merge-tree",
        "--write-tree",
        "-z",
        "--merge-base=" .. base,
        msha or "HEAD",
        sha or llm.branch,
      }
      git(args, target.path, function(m)
        if m.code > 1 then -- 1 means conflicts
          return notify(
            "git merge-tree failed, nothing changed:\n" .. vim.trim(m.stderr or ""),
            vim.log.levels.ERROR
          )
        end

        -- NUL-separated: the merged tree, then one "<mode> <oid> <stage>\t<path>" entry per side
        -- of each conflicted file, up to an empty field (git's messages follow)
        local fields = vim.split(m.stdout or "", "\0", { plain = true })
        local result, stages, conflicts, seen = vim.trim(fields[1]), {}, {}, {}
        for i = 2, #fields do
          if fields[i] == "" then
            break
          end
          table.insert(stages, fields[i])
          local path = fields[i]:match("\t(.*)$")
          if path and not seen[path] then
            seen[path] = true
            table.insert(conflicts, path)
          end
        end

        --- Make git recognize the conflicts, so they can be resolved with git tooling. Without
        --- this, the files only hold the markers as text and git sees a normal edit (" M").
        ---@param cb fun(r: vim.SystemCompleted)
        local function mark_conflicts(cb)
          local info = {}
          for _, path in ipairs(conflicts) do
            -- mode 0 drops the path's normal entry
            table.insert(info, "0 " .. ("0"):rep(#result) .. "\t" .. path .. "\0")
          end
          for _, entry in ipairs(stages) do
            table.insert(info, entry .. "\0")
          end
          git({ "update-index", "-z", "--index-info" }, target.path, cb, nil, table.concat(info))
        end

        local function record_conflicts()
          local list = table.concat(conflicts, "\0")
          git({ "hash-object", "-w", "--stdin" }, target.path, function(h)
            if h.code ~= 0 then
              return Logger.warn("could not save the conflict list: " .. vim.trim(h.stderr), CTX)
            end
            local ref = undo_ref(target, "conflicts")
            git({ "update-ref", ref, vim.trim(h.stdout) }, target.path, function(u)
              if u.code ~= 0 then
                Logger.warn("could not save the conflict list: " .. vim.trim(u.stderr), CTX)
              end
            end)
          end, nil, list)
        end

        -- the worktree brought nothing target lacks, e.g. it undid the last pull: a merge keeps
        -- that undo, only a re-pull applies those changes again
        if result == mtree then
          notify(
            ("Nothing new from %s since the last pull, %s unchanged"):format(
              llm.branch,
              label(target)
            )
          )
          record_pulled(target, llm, sha)
          return prune_backups(target.path)
        end

        local steps = {
          { "read-tree", "--reset", mtree },
          -- --reset blanks the size/mtime of changed entries (a bare read-tree blanks every entry,
          -- so the refresh would rehash every file); step 3 compares those to the files to rule out
          -- unsaved edits, so without fresh values it refuses ("not uptodate")
          { "update-index", "-q", "--refresh" },
          { "read-tree", "-m", "-u", mtree, result },
        }
        local function step(i)
          local s = steps[i]
          if not s then
            return restore_staging(target, staged, function(z)
              local function done()
                record_pulled(target, llm, sha)
                prune_backups(target.path)
                vim.cmd("checktime")
              end

              if z.code ~= 0 then
                local err = vim.trim(z.stderr or "")
                notify(
                  "Merged, but restoring your staging failed:\n" .. err .. hint,
                  vim.log.levels.WARN
                )
                return done()
              end
              if #conflicts == 0 then
                notify(
                  ("Merged %s into %s as unstaged changes%s"):format(
                    llm.branch,
                    label(target),
                    staged and ", your staged changes kept" or ""
                  )
                )
                return done()
              end

              mark_conflicts(function(c)
                local list = table.concat(conflicts, "\n")
                if c.code ~= 0 then
                  notify(
                    "Merged with conflicts, the files hold the markers but git does not list them"
                      .. " as conflicts:\n"
                      .. list
                      .. "\n"
                      .. vim.trim(c.stderr or "")
                      .. hint,
                    vim.log.levels.WARN
                  )
                else
                  record_conflicts()
                  notify(
                    "Merged with conflicts (resolvable with git tooling)\n" .. list .. hint,
                    vim.log.levels.WARN
                  )
                end
                done()
              end)
            end)
          end

          git(s, target.path, function(r)
            if r.code ~= 0 then
              return restore_staging(target, staged, function()
                local msg = "Could not apply the merge to %s, nothing changed (git %s):\n%s"
                notify(
                  msg:format(label(target), table.concat(s, " "), vim.trim(r.stderr or "")) .. hint,
                  vim.log.levels.ERROR
                )
                vim.cmd("checktime")
              end)
            end
            step(i + 1)
          end)
        end

        save_undo(target, llm, mtree, staged, function()
          step(1)
        end)
      end)
    end

    if not msha then
      return merge()
    end
    local backup = backup_ref()
    local what = "backing up " .. label(target)
    must({ "update-ref", backup, msha }, target.path, what, function()
      Logger.info(label(target) .. " backed up as " .. backup, CTX)
      merge()
    end)
  end)
end

---@param opts? { again?: boolean } again: ignore the last pull and merge from the common commit
function M.pull_from_llm_worktree(opts)
  local again = opts and opts.again
  if busy() then
    return
  end

  with_target(function(list, target)
    local main = list[1]
    warn_detached(list, main)

    local llm_wts = vim.tbl_filter(function(llm)
      return llm ~= target
    end, llm_worktrees(list, main))

    if #llm_wts == 0 then
      return notify("No LLM worktrees to pull from", vim.log.levels.WARN)
    end

    local function run(llm)
      staged_tree(target.path, function(staged, serr)
        if serr then
          return notify(
            ("Could not read %s's staging, nothing changed:\n"):format(label(target)) .. serr,
            vim.log.levels.ERROR
          )
        end

        local hint = ""
        if staged then
          hint = "\nYour staging from before the pull: git read-tree " .. staged
          Logger.info(label(target) .. "'s staged state saved as tree " .. staged, CTX)
        end

        snapshot(llm.path, function(sha, err)
          if err then
            notify("Snapshot failed, merging committed work only:\n" .. err, vim.log.levels.WARN)
          end
          local ref = sha or llm.branch

          if again then
            return git({ "merge-base", "HEAD", ref }, target.path, function(c)
              if c.code ~= 0 then
                local why = c.code == 1 and "no common commit" or vim.trim(c.stderr or "")
                return notify(
                  ("Could not find where %s started, nothing changed:\n%s"):format(llm.branch, why),
                  vim.log.levels.ERROR
                )
              end
              pull_from_base(target, llm, vim.trim(c.stdout), sha, staged, hint)
            end)
          end

          git({ "rev-parse", "--verify", "-q", pulled_ref(target, llm) }, target.path, function(b)
            if b.code == 0 then
              return pull_from_base(target, llm, vim.trim(b.stdout), sha, staged, hint)
            end

            -- first pull of this worktree: nothing recorded, let git find the common base
            local extra = sha and " + uncommitted" or ""
            local into = label(target)
            Logger.info(("Squash-merging %s%s into %s..."):format(llm.branch, extra, into), CTX)

            working_tree(target.path, function(mtree, merr)
              if merr then
                return notify(
                  ("Could not snapshot %s, nothing changed:\n"):format(into) .. merr,
                  vim.log.levels.ERROR
                )
              end

              save_undo(target, llm, mtree, staged, function()
                git({ "merge", "--squash", "--autostash", ref }, target.path, function(r)
                  local out = vim.trim((r.stdout or "") .. "\n" .. (r.stderr or ""))

                  if r.code == 0 then
                    -- clean merge, but the autostash reapply can conflict
                    git({ "diff", "--name-only", "--diff-filter=U" }, target.path, function(u)
                      local unmerged = vim.trim(u.stdout or "")
                      if unmerged ~= "" then
                        record_pulled(target, llm, sha)
                        notify(
                          "Merged, but conflicts remain (resolve with git tooling, then"
                            .. " `git reset`):\n"
                            .. unmerged
                            .. hint,
                          vim.log.levels.WARN
                        )
                        return vim.cmd("checktime")
                      end

                      restore_staging(target, staged, function(z)
                        Logger.info("git merge output:\n" .. out, CTX)
                        record_pulled(target, llm, sha)
                        if z.code ~= 0 then
                          notify(
                            "Merged, but restoring your staging failed:\n"
                              .. vim.trim(z.stderr or "")
                              .. hint,
                            vim.log.levels.WARN
                          )
                        else
                          notify(
                            ("Merged %s into %s as unstaged changes%s"):format(
                              llm.branch,
                              label(target),
                              staged and ", your staged changes kept" or ""
                            )
                          )
                        end
                        vim.cmd("checktime")
                      end)
                    end)
                  else
                    -- merge failed: unmerged files = conflict, none = never ran
                    git({ "diff", "--name-only", "--diff-filter=U" }, target.path, function(u)
                      local unmerged = vim.trim(u.stdout or "")
                      if unmerged ~= "" then
                        record_pulled(target, llm, sha)
                        notify(
                          "Conflicts (resolve with git tooling, then `git reset`):\n"
                            .. unmerged
                            .. hint,
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
            end)
          end)
        end)
      end)
    end

    if #llm_wts == 1 then
      return run(llm_wts[1])
    end

    select(llm_wts, {
      prompt = ("Merge worktree into %s (unstaged)"):format(label(target)),
      format_item = function(llm)
        return llm.branch .. "  (" .. llm.path .. ")"
      end,
    }, function(choice)
      if choice then
        run(choice)
      end
    end)
  end)
end

--- Put the cwd's worktree back to right before its last pull: files on disk (untracked ones too),
--- staging, and the pulled worktree's pulled mark, so the next pull offers those changes again.
function M.undo_pull()
  if busy() then
    return
  end

  with_target(function(_, target)
    local undo = undo_ref(target, "pull")
    local name = label(target)

    local fmt = "--format=%(parent)%0a%(contents)"
    git({ "for-each-ref", fmt, undo }, target.path, function(l)
      if l.code ~= 0 then
        local err = vim.trim(l.stderr or "")
        return notify("Could not read " .. undo .. ": " .. err, vim.log.levels.ERROR)
      end

      if l.stdout == "" then
        return notify("No pull to undo", vim.log.levels.WARN)
      end

      local parents = vim.split(l.stdout:match("^[^\n]*"), " ", { plain = true, trimempty = true })
      local branch, pulled = l.stdout:match("\nbranch (%S+)\npulled (%S+)")

      if not branch then
        local subject = l.stdout:match("\n([^\n]*)") or ""
        return notify(
          ("%s does not point to an undo point (commit message: %q)"):format(undo, subject),
          vim.log.levels.ERROR
        )
      end

      local pulled_mark = pulled_ref(target, { path = "", branch = branch })

      must({ "rev-parse", "HEAD" }, target.path, "rev-parse HEAD in " .. name, function(head)
        if head ~= parents[1] then
          local msg = "HEAD moved since the pull, not undoing. Files before it:"
            .. " git checkout %s -- ."
          return notify(msg:format(undo), vim.log.levels.WARN)
        end

        local ask = "Undo the pull of %s into %s? Edits made since are discarded (backed up first)"
        if vim.fn.confirm(ask:format(branch, name), "&Yes\n&No", 2) ~= 1 then
          return
        end

        snapshot(target.path, function(msha, merr)
          if merr then
            return notify(
              ("Could not back up %s, nothing changed:\n"):format(name) .. merr,
              vim.log.levels.ERROR
            )
          end
          local backup = msha and backup_ref()
          local saved = backup
              and ("\nWhat %s had since the pull is saved as %s"):format(name, backup)
            or ""

          local steps = {
            -- read-tree -u only deletes files the index tracks, and files the pull added are
            -- untracked: add -A tracks them so it deletes them too (and replaces conflict entries)
            { "add", "-A" },
            { "read-tree", "-u", "--reset", undo },
            parents[2] and { "read-tree", parents[2] } or { "reset", "-q" },
            pulled == "none" and { "update-ref", "-d", pulled_mark }
              or { "update-ref", pulled_mark, pulled },
            { "update-ref", "-d", undo },
            { "update-ref", "-d", undo_ref(target, "conflicts") },
          }

          local function step(i)
            local s = steps[i]
            if not s then
              notify(("%s is back to right before the pull of %s%s"):format(name, branch, saved))
              prune_backups(target.path)
              return vim.cmd("checktime")
            end

            git(s, target.path, function(r)
              if r.code ~= 0 then
                notify(
                  ("Undo stopped at git %s:\n%s%s"):format(
                    table.concat(s, " "),
                    vim.trim(r.stderr or ""),
                    saved
                  ),
                  vim.log.levels.ERROR
                )
                return vim.cmd("checktime")
              end
              step(i + 1)
            end)
          end

          if not backup then
            return step(1)
          end

          local what = ("Backing up %s (nothing changed)"):format(name)
          must({ "update-ref", backup, msha }, target.path, what, function()
            step(1)
          end)
        end)
      end)
    end)
  end)
end

--- Put the index entry of each conflicted file back to what it was before the pull (unstaged if it
--- was not staged).
function M.restore_resolved_staging()
  if busy() then
    return
  end

  with_target(function(_, target)
    local undo = undo_ref(target, "pull")
    git({ "cat-file", "blob", undo_ref(target, "conflicts") }, target.path, function(c)
      if c.code ~= 0 then
        return notify("No conflicted pull to restore the staging of", vim.log.levels.WARN)
      end
      local paths = vim.split(c.stdout, "\0", { plain = true, trimempty = true })

      git({ "diff", "--name-only", "--diff-filter=U" }, target.path, function(u)
        local unmerged = vim.trim(u.stdout or "")
        if unmerged ~= "" then
          return notify("Resolve these first:\n" .. unmerged, vim.log.levels.WARN)
        end

        -- parent 2 = the staging before the pull, none = nothing was staged (parent 1 = HEAD)
        git({ "rev-parse", "--verify", "-q", undo .. "^2" }, target.path, function(p)
          local source = p.code == 0 and vim.trim(p.stdout) or undo .. "^1"
          local restore = {
            "--literal-pathspecs",
            "restore",
            "--source=" .. source,
            "--staged",
            "--pathspec-from-file=-",
            "--pathspec-file-nul",
          }
          git(restore, target.path, function(r)
            if r.code ~= 0 then
              return notify(
                "Could not restore the staging:\n" .. vim.trim(r.stderr or ""),
                vim.log.levels.ERROR
              )
            end
            notify("Staging from before the pull restored for:\n" .. table.concat(paths, "\n"))
          end, nil, c.stdout)
        end)
      end)
    end)
  end)
end

function M.overwrite_llm_worktree()
  if busy() then
    return
  end
  pick_llm_worktree("Sync %s into", function(target, llm)
    if not target.branch then
      return notify(label(target) .. " has a detached HEAD", vim.log.levels.ERROR)
    end

    local function mirror(llm_sha, llm_head, target_sha, target_head)
      local ref = backup_ref()

      local backup = { "update-ref", ref, llm_sha or llm_head }
      must(backup, llm.path, "backing up the worktree", function()
        Logger.info("worktree backed up as " .. ref, CTX)

        local steps = { { "reset", "--hard", target_sha or target_head }, { "clean", "-fd" } }
        if target_sha then
          table.insert(steps, { "reset", "-q", target_head })
        end

        local undo = { { "reset", "--hard", ref } }
        if llm_sha then
          table.insert(undo, { "reset", "-q", llm_head })
        end

        local function rollback(why)
          local function undo_step(i)
            local u = undo[i]
            if not u then
              return notify(
                why .. "\nThe worktree was restored from " .. ref .. ".",
                vim.log.levels.ERROR
              )
            end

            git(u, llm.path, function(r)
              if r.code ~= 0 then
                local msg = "%s\nRestoring failed too (git %s):\n%s\nRestore by hand: %s"
                return notify(
                  msg:format(
                    why,
                    table.concat(u, " "),
                    vim.trim(r.stderr or ""),
                    "git reset --hard " .. ref
                  ),
                  vim.log.levels.ERROR
                )
              end

              undo_step(i + 1)
            end)
          end

          undo_step(1)
        end

        local function step(i)
          local s = steps[i]
          if not s then
            notify(
              (
                "%s now mirrors %s.\n"
                .. "What it had is saved as %s (restore files: git checkout %s -- .)"
              ):format(llm.branch, target.branch, ref, ref)
            )
            prune_backups(llm.path)
            local mark = { "update-ref", pulled_ref(target, llm), target_sha or target_head }
            return git(mark, llm.path, function(u)
              if u.code ~= 0 then
                Logger.warn("could not record the mirrored state: " .. vim.trim(u.stderr), CTX)
              end
            end)
          end

          git(s, llm.path, function(r)
            if r.code ~= 0 then
              return rollback(
                ("git %s failed:\n%s"):format(table.concat(s, " "), vim.trim(r.stderr or ""))
              )
            end
            step(i + 1)
          end)
        end
        step(1)
      end)
    end

    local function do_merge()
      Logger.info(("Mirroring %s onto %s..."):format(target.branch, llm.branch), CTX)

      snapshot(llm.path, function(llm_sha, llm_err, llm_tree)
        if llm_err then
          return notify(
            "Could not snapshot the worktree, nothing changed:\n" .. llm_err,
            vim.log.levels.ERROR
          )
        end

        must({ "rev-parse", "HEAD" }, llm.path, "rev-parse HEAD in the worktree", function(llm_head)
          local what = "rev-parse HEAD in " .. label(target)

          must({ "rev-parse", "HEAD" }, target.path, what, function(target_head)
            snapshot(target.path, function(target_sha, target_err)
              if target_err then
                return notify(
                  ("Could not snapshot %s, nothing changed:\n"):format(label(target)) .. target_err,
                  vim.log.levels.ERROR
                )
              end

              working_tree(llm.path, function(llm_tree_now, now_err)
                if now_err then
                  return notify(
                    "Could not re-check the worktree, nothing changed:\n" .. now_err,
                    vim.log.levels.ERROR
                  )
                end

                if llm_tree_now ~= llm_tree then
                  return notify(
                    "The worktree changed while preparing, nothing was changed."
                      .. " Try to run again.",
                    vim.log.levels.WARN
                  )
                end

                mirror(llm_sha, llm_head, target_sha, target_head)
              end)
            end)
          end)
        end)
      end)
    end

    if vim.uv.fs_stat(llm.path .. "/.git") then
      return do_merge()
    end

    Logger.warn("Worktree dir missing, recreating " .. llm.path, CTX)
    git({ "worktree", "prune" }, target.path, function()
      git({ "worktree", "add", llm.path, llm.branch }, target.path, function(a)
        if a.code ~= 0 then
          return notify(vim.trim(a.stderr), vim.log.levels.ERROR)
        end
        do_merge()
      end)
    end)
  end)
end

-- Stage every unstaged changes in current worktree that the LLM worktree does not have.
function M.stage_unshared_hunks()
  if busy() then
    return
  end
  pick_llm_worktree("Stage hunks of %s missing from:", function(target, llm)
    if not vim.uv.fs_stat(llm.path .. "/.git") then
      return notify("Worktree dir missing: " .. llm.path, vim.log.levels.ERROR)
    end
    local index_before, index_err, index_read
    staged_tree(target.path, function(tree, err)
      index_before, index_err, index_read = tree, err, true
    end)
    local diff_file = vim.fn.tempname()
    -- --output keeps git from going through the text-mode pipe, which would eat any \r
    git(
      {
        "diff",
        "--no-color",
        "--no-ext-diff",
        "--no-textconv",
        "--unified=0",
        "--output=" .. diff_file,
      },
      target.path,
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
          return notify("No unstaged hunks in " .. label(target))
        end

        local skipped = {}
        local function warn_skipped()
          if #skipped == 0 then
            return
          end

          local msg = "%d file(s) NOT compared (renamed, special path or unreadable),"
            .. " hunks left unstaged:\n  %s"
          notify(msg:format(#skipped, table.concat(skipped, "\n  ")), vim.log.levels.WARN)
        end

        local function stage()
          warn_skipped()
          local parts, staged, nfiles, shared, uncompared = {}, 0, 0, 0, 0
          for _, f in ipairs(files) do
            for _, h in ipairs(f.hunks) do
              if h.stage == false then
                shared = shared + 1
              elseif h.stage == nil then
                uncompared = uncompared + 1
              end
            end
          end
          local uncompared_note = uncompared > 0 and (", %d not compared"):format(uncompared) or ""

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
              ("Nothing to stage: %d of %d unstaged hunk(s) are already in %s%s"):format(
                shared,
                #tasks,
                llm.branch,
                uncompared_note
              )
            )
          end

          if not vim.wait(2000, function()
            return index_read
          end, 10) then
            return notify(
              "Could not read the index (timed out), nothing staged.",
              vim.log.levels.ERROR
            )
          end

          if index_err then
            return notify(
              "Could not read the index, nothing staged:\n" .. index_err,
              vim.log.levels.ERROR
            )
          end

          staged_tree(target.path, function(index_now, now_err)
            if now_err then
              return notify(
                "Could not read the index, nothing staged:\n" .. now_err,
                vim.log.levels.ERROR
              )
            end

            if index_now ~= index_before then
              return notify(
                "The index changed while checking hunks, nothing staged. Run it again.",
                vim.log.levels.WARN
              )
            end

            local patch = vim.fn.tempname()
            write_file(patch, table.concat(parts))
            git({ "apply", "--cached", "--unidiff-zero", patch }, target.path, function(r)
              os.remove(patch)
              if r.code ~= 0 then
                return notify(
                  "git apply --cached failed, nothing staged:\n" .. vim.trim(r.stderr),
                  vim.log.levels.ERROR
                )
              end

              notify(
                ("Staged %d of %d hunk(s) in %d file(s); %d already in %s stay unstaged%s"):format(
                  staged,
                  #tasks,
                  nfiles,
                  shared,
                  llm.branch,
                  uncompared_note
                )
              )
            end)
          end)
        end

        local progress_id
        ---@param done integer files checked so far
        ---@param status "running"|"success"|"failed"
        local function progress(done, status)
          local msg = ("checked %d/%d files"):format(done, #files)
          progress_id = vim.api.nvim_echo({ { msg } }, false, {
            id = progress_id,
            kind = "progress",
            source = CTX,
            title = TITLE,
            status = status,
            percent = math.floor(done / #files * 100),
          })
        end

        local function check_file(i)
          local f = files[i]
          progress(i - 1, f and "running" or "success")
          if not f then
            return stage()
          end

          local path = diff_path(f.header)
          if not path then
            table.insert(skipped, vim.trim(f.header:match("^[^\n]*")))
            return check_file(i + 1)
          end

          ---@param is_shared fun(h: DiffHunk): boolean
          local function finish(is_shared)
            for _, h in ipairs(f.hunks) do
              h.stage = not is_shared(h)
              Logger.debug(
                ("%s %s: %s"):format(
                  path,
                  vim.trim(h.head),
                  h.stage and "missing from worktree, will stage"
                    or "already in worktree, stays unstaged"
                ),
                CTX
              )
            end
            check_file(i + 1)
          end

          local target_file, llm_file = target.path .. "/" .. path, llm.path .. "/" .. path
          local mtext, wtext = read_file(target_file), read_file(llm_file)
          if f.header:find("\ndeleted file mode", 1, true) then
            return finish(function()
              return wtext == nil
            end)
          elseif mtext == nil then
            table.insert(skipped, path)
            return check_file(i + 1)
          elseif wtext == nil then
            return finish(function()
              return false
            end)
          elseif mtext == wtext then
            return finish(function()
              return true
            end)
          end

          git(
            {
              "diff",
              "--no-index",
              "--no-color",
              "--no-ext-diff",
              "--no-textconv",
              "--unified=0",
              "--ignore-space-at-eol",
              "--",
              target_file,
              llm_file,
            },
            target.path,
            function(r)
              -- 0 = same, 1 = they differ; anything else says nothing about the worktree
              if r.code ~= 0 and r.code ~= 1 then
                progress(i - 1, "failed")
                return notify(
                  ("git diff --no-index failed (exit %d), nothing staged:\n%s"):format(
                    r.code,
                    vim.trim(r.stderr or "")
                  ),
                  vim.log.levels.ERROR
                )
              end
              local regions = diff_regions(r.stdout or "")
              finish(function(h)
                local lo, hi = changed_span(h)
                for _, g in ipairs(regions) do
                  if overlaps(lo, hi, g[1], g[2]) then
                    return false
                  end
                end
                return true
              end)
            end
          )
        end
        check_file(1)
      end
    )
  end)
end
return M
