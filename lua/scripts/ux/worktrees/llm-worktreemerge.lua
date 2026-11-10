local M = {}

local TITLE = "LlmWorktreeMerge"
local CTX = "llm-worktreemerge"
local notify = require("config.notifylog").bind({ title = TITLE, ctx = CTX })

---@class Worktree
---@field path string
---@field branch string? nil when the worktree has a detached HEAD

local in_flight = 0

--- Run git async; cb runs on the main loop once git exits.
---@param args string[]
---@param cwd string
---@param cb fun(r: vim.SystemCompleted)
---@param env? table<string, string> extra environment variables for this git call
local function git(args, cwd, cb, env)
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
    { cwd = cwd, text = true, env = env },
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

--- git that ends the whole chain with an error popup when it fails; cb gets the trimmed stdout.
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

-- git add -A hashes every untracked, non-ignored file, so a big untracked directory (build output,
-- a dependency folder nobody gitignored) makes a snapshot slow. Past this many, snapshot refuses.
local UNTRACKED_LIMIT = 2000

---@param cwd string
---@param cb fun(sha: string?, err: string?) sha nil + err nil = nothing to snapshot
local function take_snapshot(cwd, cb)
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

---@param cwd string
---@param cb fun(sha: string?, err: string?) sha nil + err nil = nothing to snapshot
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

--- Tree of what is staged in cwd right now, so a later reset can put the staging back.
--- Gives nil when nothing is staged or the index cannot be written (unmerged entries).
---@param cwd string
---@param cb fun(tree: string?)
local function index_tree(cwd, cb)
  git({ "write-tree" }, cwd, function(a)
    if a.code ~= 0 then
      return cb(nil)
    end
    local tree = vim.trim(a.stdout)
    git({ "rev-parse", "HEAD^{tree}" }, cwd, function(b)
      if b.code ~= 0 or vim.trim(b.stdout) == tree then
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
      index_tree(main.path, function(staged)
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
          Logger.info(
            ("Squash-merging %s%s into main..."):format(wt.branch, sha and " + uncommitted" or ""),
            CTX
          )

          git({ "merge", "--squash", "--autostash", ref }, main.path, function(r)
            local out = vim.trim((r.stdout or "") .. "\n" .. (r.stderr or ""))
            if r.code == 0 then
              git({ "diff", "--name-only", "--diff-filter=U" }, main.path, function(u)
                local unmerged = vim.trim(u.stdout or "")
                if unmerged ~= "" then
                  notify(
                    "Merged, but conflicts remain (resolve with git tooling, then `git reset`):\n"
                      .. unmerged
                      .. hint,
                    vim.log.levels.WARN
                  )
                  return vim.cmd("checktime")
                end

                -- index back to what was staged before (HEAD when nothing was); files stay as
                -- merged
                local reset = staged and { "read-tree", staged } or { "reset", "-q" }
                git(reset, main.path, function(z)
                  Logger.info("git merge output:\n" .. out, CTX)
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
              git({ "diff", "--name-only", "--diff-filter=U" }, main.path, function(u)
                local unmerged = vim.trim(u.stdout or "")
                if unmerged ~= "" then
                  notify(
                    "Conflicts (resolve with git tooling, then `git reset`):\n" .. unmerged .. hint,
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
      local function do_merge()
        Logger.info(("Mirroring %s onto %s..."):format(main.branch, wt.branch), CTX)
        snapshot(wt.path, function(wsha, werr)
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
                -- the snapshot has the branch tip as its parent, so the committed work stays
                -- reachable
                local ref = "refs/wt-backup/"
                  .. os.date("%Y%m%d-%H%M%S")
                  .. ("-%03d"):format(math.floor(vim.uv.hrtime() / 1e6) % 1000)
                must(
                  { "update-ref", ref, wsha or wtip },
                  wt.path,
                  "backing up the worktree",
                  function()
                    Logger.info("worktree backed up as " .. ref, CTX)
                    local steps = { { "reset", "--hard", msha or mhead }, { "clean", "-fd" } }
                    if msha then
                      table.insert(steps, { "reset", "-q", mhead })
                    end
                    local function step(i)
                      local s = steps[i]
                      if not s then
                        return notify(
                          (
                            "%s now mirrors %s.\n"
                            .. "What it had is saved as %s (restore files: git checkout %s -- .)"
                          ):format(wt.branch, main.branch, ref, ref)
                        )
                      end
                      must(
                        s,
                        wt.path,
                        "git " .. table.concat(s, " ") .. " (worktree saved as " .. ref .. ")",
                        function()
                          step(i + 1)
                        end
                      )
                    end
                    step(1)
                  end
                )
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
  if busy() then
    return
  end
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
            -- 0 = the reverse applies (worktree has it), 1 = it does not (worktree lacks it).
            -- Anything else (128: corrupt patch, git failure) says nothing about the worktree.
            if r.code ~= 0 and r.code ~= 1 then
              return notify(
                ("git apply --check failed (exit %d), nothing staged:\n%s"):format(
                  r.code,
                  vim.trim(r.stderr or "")
                ),
                vim.log.levels.ERROR
              )
            end
            t.hunk.stage = r.code == 1
            Logger.debug(
              ("hunk %d/%d %s %s: %s"):format(
                i,
                #tasks,
                vim.trim(t.file.header:match("^[^\n]*")),
                vim.trim(t.hunk.head),
                t.hunk.stage and "missing from worktree, will stage"
                  or "already in worktree, stays unstaged"
              ),
              CTX
            )
            check(i + 1)
          end)
        end
        check(1)
      end
    )
  end)
end

return M
