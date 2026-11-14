local M = {}

local TITLE = "LlmWorktreeMerge"
local CTX = "llm-worktreemerge"
local notify = require("config.notifylog").bind({ title = TITLE, ctx = CTX })

---@class Worktree
---@field path string
---@field branch string? nil when the worktree has a detached HEAD

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

local UNTRACKED_LIMIT = 2000
local BACKUP_KEEP = 20
local PULLED = "refs/wt-pulled/"
local UNDO = "refs/wt-undo/pull"
local BACKUP_PREFIX = "refs/wt-backup/"
local BACKUP_NAME = "^" .. vim.pesc(BACKUP_PREFIX) .. "%d%d%d%d%d%d%d%d%-%d%d%d%d%d%d%-%d%d%d$"

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
  return list
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

    select(llm_wts, {
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
local function restore_staging(main, staged, cb)
  local reset = staged and { "read-tree", staged } or { "reset", "-q" }
  git(reset, main.path, cb)
end

---@param main Worktree
---@param wt Worktree
---@param tree string main's files on disk, from working_tree
---@param staged string? main's staging, from staged_tree
---@param cb fun()
local function save_undo(main, wt, tree, staged, cb)
  local what = "Saving the undo point (nothing changed)"
  git({ "rev-parse", "--verify", "-q", PULLED .. wt.branch }, main.path, function(p)
    -- what undo_pull resets the pulled mark to, "none" = first pull
    local msg = ("worktreemerge undo point\n\nbranch %s\npulled %s"):format(
      wt.branch,
      p.code == 0 and vim.trim(p.stdout) or "none"
    )
    -- parents: HEAD, then the staging if any (a parent must be a commit, so it gets wrapped)
    local function save(parents)
      local args = vim.list_extend({ "commit-tree", tree, "-p", "HEAD" }, parents)
      vim.list_extend(args, { "-m", msg })
      must(args, main.path, what, function(point)
        must({ "update-ref", UNDO, point }, main.path, what, function()
          cb()
        end)
      end)
    end

    if not staged then
      return save({})
    end

    local wrap = { "commit-tree", staged, "-p", "HEAD", "-m", "worktreemerge staging" }
    must(wrap, main.path, what, function(s)
      save({ "-p", s })
    end)
  end)
end

---@param main Worktree
---@param wt Worktree
---@param sha string? worktree snapshot this pull brought into main. nil = its HEAD
local function record_pulled(main, wt, sha)
  local function save(commit)
    git({ "update-ref", PULLED .. wt.branch, commit }, main.path, function(r)
      if r.code ~= 0 then
        Logger.warn("could not record the pulled state: " .. vim.trim(r.stderr or ""), CTX)
      end
    end)
  end

  if sha then
    return save(sha)
  end
  git({ "rev-parse", wt.branch }, main.path, function(r)
    if r.code ~= 0 then
      return Logger.warn("could not record the pulled state: " .. vim.trim(r.stderr or ""), CTX)
    end
    save(vim.trim(r.stdout))
  end)
end

--- Merge the worktree into main starting from the previous pull: only what changed in the worktree
--- since then comes in, and everything else in main (its own edits) stays.
---@param main Worktree
---@param wt Worktree
---@param base string commit of the previous pull
---@param sha string? snapshot commit of the worktree now; nil = its HEAD
---@param staged string? main's staged state, put back afterwards
---@param hint string
local function pull_from_base(main, wt, base, sha, staged, hint)
  snapshot(main.path, function(msha, merr, mtree)
    if merr then
      return notify("Could not snapshot main, nothing changed:\n" .. merr, vim.log.levels.ERROR)
    end

    local function merge()
      local args = {
        "merge-tree",
        "--write-tree",
        "-z",
        "--merge-base=" .. base,
        msha or "HEAD",
        sha or wt.branch,
      }
      git(args, main.path, function(m)
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
          git({ "update-index", "-z", "--index-info" }, main.path, cb, nil, table.concat(info))
        end

        -- the worktree brought nothing main lacks, e.g. main undid the last pull: a merge keeps
        -- that undo, only a re-pull applies those changes again
        if result == mtree then
          notify(("Nothing new from %s since the last pull, main unchanged"):format(wt.branch))
          record_pulled(main, wt, sha)
          return prune_backups(main.path)
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
            return restore_staging(main, staged, function(z)
              local function done()
                record_pulled(main, wt, sha)
                prune_backups(main.path)
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
                  ("Merged %s into main as unstaged changes%s"):format(
                    wt.branch,
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
                  notify(
                    "Merged with conflicts (resolve with git tooling, then `git reset`):\n"
                      .. list
                      .. hint,
                    vim.log.levels.WARN
                  )
                end
                done()
              end)
            end)
          end

          git(s, main.path, function(r)
            if r.code ~= 0 then
              return restore_staging(main, staged, function()
                local msg = "Could not apply the merge to main, nothing changed (git %s):\n%s"
                notify(
                  msg:format(table.concat(s, " "), vim.trim(r.stderr or "")) .. hint,
                  vim.log.levels.ERROR
                )
                vim.cmd("checktime")
              end)
            end
            step(i + 1)
          end)
        end

        save_undo(main, wt, mtree, staged, function()
          step(1)
        end)
      end)
    end

    if not msha then
      return merge()
    end
    local backup = backup_ref()
    must({ "update-ref", backup, msha }, main.path, "backing up main", function()
      Logger.info("main backed up as " .. backup, CTX)
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
      staged_tree(main.path, function(staged, serr)
        if serr then
          return notify(
            "Could not read main's staging, nothing changed:\n" .. serr,
            vim.log.levels.ERROR
          )
        end

        local hint = ""
        if staged then
          hint = "\nYour staging from before the pull: git read-tree " .. staged
          Logger.info("main's staged state saved as tree " .. staged, CTX)
        end

        snapshot(wt.path, function(sha, err)
          if err then
            notify("Snapshot failed, merging committed work only:\n" .. err, vim.log.levels.WARN)
          end
          local ref = sha or wt.branch

          if again then
            return git({ "merge-base", "HEAD", ref }, main.path, function(c)
              if c.code ~= 0 then
                local why = c.code == 1 and "no common commit" or vim.trim(c.stderr or "")
                return notify(
                  ("Could not find where %s started, nothing changed:\n%s"):format(wt.branch, why),
                  vim.log.levels.ERROR
                )
              end
              pull_from_base(main, wt, vim.trim(c.stdout), sha, staged, hint)
            end)
          end

          git({ "rev-parse", "--verify", "-q", PULLED .. wt.branch }, main.path, function(b)
            if b.code == 0 then
              return pull_from_base(main, wt, vim.trim(b.stdout), sha, staged, hint)
            end

            -- first pull of this worktree: nothing recorded, let git find the common base
            local extra = sha and " + uncommitted" or ""
            Logger.info(("Squash-merging %s%s into main..."):format(wt.branch, extra), CTX)

            working_tree(main.path, function(mtree, merr)
              if merr then
                return notify(
                  "Could not snapshot main, nothing changed:\n" .. merr,
                  vim.log.levels.ERROR
                )
              end

              save_undo(main, wt, mtree, staged, function()
                git({ "merge", "--squash", "--autostash", ref }, main.path, function(r)
                  local out = vim.trim((r.stdout or "") .. "\n" .. (r.stderr or ""))

                  if r.code == 0 then
                    -- clean merge, but the autostash reapply can conflict
                    git({ "diff", "--name-only", "--diff-filter=U" }, main.path, function(u)
                      local unmerged = vim.trim(u.stdout or "")
                      if unmerged ~= "" then
                        record_pulled(main, wt, sha)
                        notify(
                          "Merged, but conflicts remain (resolve with git tooling, then"
                            .. " `git reset`):\n"
                            .. unmerged
                            .. hint,
                          vim.log.levels.WARN
                        )
                        return vim.cmd("checktime")
                      end

                      restore_staging(main, staged, function(z)
                        Logger.info("git merge output:\n" .. out, CTX)
                        record_pulled(main, wt, sha)
                        if z.code ~= 0 then
                          notify(
                            "Merged, but restoring your staging failed:\n"
                              .. vim.trim(z.stderr or "")
                              .. hint,
                            vim.log.levels.WARN
                          )
                        else
                          notify(
                            ("Merged %s into main as unstaged changes%s"):format(
                              wt.branch,
                              staged and ", your staged changes kept" or ""
                            )
                          )
                        end
                        vim.cmd("checktime")
                      end)
                    end)
                  else
                    -- merge failed: unmerged files = conflict, none = never ran
                    git({ "diff", "--name-only", "--diff-filter=U" }, main.path, function(u)
                      local unmerged = vim.trim(u.stdout or "")
                      if unmerged ~= "" then
                        record_pulled(main, wt, sha)
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

--- Put main back to right before the last pull: files on disk (untracked ones too), staging, and
--- the worktree's pulled mark, so the next pull offers those changes again.
function M.undo_pull()
  if busy() then
    return
  end
  local dir = vim.uv.cwd()
  if not dir then
    return notify("No working directory", vim.log.levels.ERROR)
  end

  git({ "worktree", "list", "--porcelain" }, dir, function(w)
    if w.code ~= 0 then
      return notify("Not a git repo: " .. dir, vim.log.levels.ERROR)
    end
    local main = parse(w.stdout)[1]

    local fmt = "--format=%(parent)%0a%(contents)"
    git({ "for-each-ref", fmt, UNDO }, main.path, function(l)
      if l.code ~= 0 then
        local err = vim.trim(l.stderr or "")
        return notify("Could not read " .. UNDO .. ": " .. err, vim.log.levels.ERROR)
      end
      if l.stdout == "" then
        return notify("No pull to undo", vim.log.levels.WARN)
      end

      local parents = vim.split(l.stdout:match("^[^\n]*"), " ", { plain = true, trimempty = true })
      local branch, pulled = l.stdout:match("\nbranch (%S+)\npulled (%S+)")

      if not branch then
        local subject = l.stdout:match("\n([^\n]*)") or ""
        return notify(
          ("%s does not point to an undo point (commit message: %q)"):format(UNDO, subject),
          vim.log.levels.ERROR
        )
      end

      must({ "rev-parse", "HEAD" }, main.path, "rev-parse HEAD in main", function(head)
        if head ~= parents[1] then
          local msg = "HEAD moved since the pull, not undoing. Files before it:"
            .. " git checkout %s -- ."
          return notify(msg:format(UNDO), vim.log.levels.WARN)
        end

        local ask = "Undo the pull of %s? Edits made in main since are discarded (backed up first)"
        if vim.fn.confirm(ask:format(branch), "&Yes\n&No", 2) ~= 1 then
          return
        end

        snapshot(main.path, function(msha, merr)
          if merr then
            return notify(
              "Could not back up main, nothing changed:\n" .. merr,
              vim.log.levels.ERROR
            )
          end
          local backup = msha and backup_ref()
          local saved = backup and ("\nWhat main had since the pull is saved as " .. backup) or ""

          local steps = {
            -- the index takes the files on disk, so the next step also removes the ones the pull
            -- added (it only removes files the index has); this also clears conflict stages
            { "add", "-A" },
            { "read-tree", "-u", "--reset", UNDO },
            parents[2] and { "read-tree", parents[2] } or { "reset", "-q" },
            pulled == "none" and { "update-ref", "-d", PULLED .. branch }
              or { "update-ref", PULLED .. branch, pulled },
            { "update-ref", "-d", UNDO },
          }

          local function step(i)
            local s = steps[i]
            if not s then
              notify(("Main is back to right before the pull of %s%s"):format(branch, saved))
              prune_backups(main.path)
              return vim.cmd("checktime")
            end

            git(s, main.path, function(r)
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

          local what = "Backing up main (nothing changed)"
          must({ "update-ref", backup, msha }, main.path, what, function()
            step(1)
          end)
        end)
      end)
    end)
  end)
end

function M.overwrite_llm_worktree()
  if busy() then
    return
  end
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
      local function mirror(wsha, wtip, msha, mhead)
        local ref = backup_ref()

        must({ "update-ref", ref, wsha or wtip }, wt.path, "backing up the worktree", function()
          Logger.info("worktree backed up as " .. ref, CTX)
          local steps = { { "reset", "--hard", msha or mhead }, { "clean", "-fd" } }
          if msha then
            table.insert(steps, { "reset", "-q", mhead })
          end

          local undo = { { "reset", "--hard", ref } }
          if wsha then
            table.insert(undo, { "reset", "-q", wtip })
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

              git(u, wt.path, function(r)
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
                ):format(wt.branch, main.branch, ref, ref)
              )
              prune_backups(wt.path)
              return git({ "update-ref", PULLED .. wt.branch, msha or mhead }, wt.path, function(u)
                if u.code ~= 0 then
                  Logger.warn("could not record the mirrored state: " .. vim.trim(u.stderr), CTX)
                end
              end)
            end

            git(s, wt.path, function(r)
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
        Logger.info(("Mirroring %s onto %s..."):format(main.branch, wt.branch), CTX)
        snapshot(wt.path, function(wsha, werr, wtree)
          if werr then
            return notify(
              "Could not snapshot the worktree, nothing changed:\n" .. werr,
              vim.log.levels.ERROR
            )
          end
          must({ "rev-parse", "HEAD" }, wt.path, "rev-parse HEAD in the worktree", function(wtip)
            must({ "rev-parse", "HEAD" }, main.path, "rev-parse HEAD in main", function(mhead)
              snapshot(main.path, function(msha, merr)
                if merr then
                  return notify(
                    "Could not snapshot main, nothing changed:\n" .. merr,
                    vim.log.levels.ERROR
                  )
                end
                working_tree(wt.path, function(wtree2, err2)
                  if err2 then
                    return notify(
                      "Could not re-check the worktree, nothing changed:\n" .. err2,
                      vim.log.levels.ERROR
                    )
                  end
                  if wtree2 ~= wtree then
                    return notify(
                      "The worktree changed while preparing, nothing was changed."
                        .. " Try to run again.",
                      vim.log.levels.WARN
                    )
                  end
                  mirror(wsha, wtip, msha, mhead)
                end)
              end)
            end)
          end)
        end)
      end

      if vim.uv.fs_stat(wt.path .. "/.git") then
        return do_merge()
      end

      Logger.warn("Worktree dir missing, recreating " .. wt.path, CTX)
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
    select(llm_wts, {
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

-- Stage every unstaged changes in main that the LLM worktree does not have.
function M.stage_unshared_hunks()
  if busy() then
    return
  end
  pick_llm_worktree("Stage hunks missing from", function(main, wt)
    if not vim.uv.fs_stat(wt.path .. "/.git") then
      return notify("Worktree dir missing: " .. wt.path, vim.log.levels.ERROR)
    end
    local index_before, index_err, index_read
    staged_tree(main.path, function(tree, err)
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
                wt.branch,
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

          staged_tree(main.path, function(index_now, now_err)
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
            git({ "apply", "--cached", "--unidiff-zero", patch }, main.path, function(r)
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
                  wt.branch,
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

          local main_file, wt_file = main.path .. "/" .. path, wt.path .. "/" .. path
          local mtext, wtext = read_file(main_file), read_file(wt_file)
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
              main_file,
              wt_file,
            },
            main.path,
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
