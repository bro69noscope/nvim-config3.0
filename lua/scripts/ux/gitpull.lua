local M = {}

M.opts = {
  args = { "--ff-only" }, -- extra args for git pull
}

local function git(args, cwd, cb)
  vim.system(vim.list_extend({ "git" }, args), { cwd = cwd, text = true }, vim.schedule_wrap(cb))
end

function M.pull()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" or vim.fn.isdirectory(dir) == 0 then
    dir = vim.uv.cwd()
  end

  git({ "rev-parse", "--abbrev-ref", "HEAD" }, dir, function(b)
    if b.code ~= 0 then
      return vim.notify("Not a git repo", vim.log.levels.ERROR, { title = "GitPull" })
    end
    local branch = vim.trim(b.stdout)

    local function run(extra)
      local args = vim.list_extend({ "pull" }, M.opts.args)
      vim.list_extend(args, extra)
      vim.notify("Pulling " .. branch .. "...", vim.log.levels.INFO, { title = "GitPull" })
      git(args, dir, function(r)
        local out = vim.trim(r.stdout .. "\n" .. r.stderr)
        vim.notify(
          out,
          r.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR,
          { title = "GitPull" }
        )
        vim.cmd("checktime")
      end)
    end

    -- upstream set? plain pull. Else pull origin <branch>.
    git({ "rev-parse", "--abbrev-ref", "@{u}" }, dir, function(u)
      if u.code == 0 then
        run({})
      else
        run({ "origin", branch })
      end
    end)
  end)
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
end

return M
