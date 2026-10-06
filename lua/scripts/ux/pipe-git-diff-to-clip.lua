-- Pipe git diffs to clipboard
local M = {}

-- opts.staged: false/nil = unstaged only, true = staged + unstaged (vs HEAD)
-- opts.cached: true = staged only
local function diff_cmd(opts)
  opts = opts or {}
  if opts.cached then
    return "git diff --cached"
  elseif opts.staged then
    return "git diff HEAD"
  end
  return "git diff"
end

M.file_diff = function(opts)
  local file = vim.fn.expand("%:t")

  if vim.bo.buftype ~= "" or file == "" then
    vim.notify("No valid file to diff", vim.log.levels.WARN)
    return
  end

  vim.cmd("silent !" .. diff_cmd(opts) .. " -- % | " .. ClipExecutable)

  if vim.v.shell_error ~= 0 then
    vim.notify("git diff failed for " .. file, vim.log.levels.ERROR)
    return
  end

  vim.notify("Git diff for " .. file .. " copied to clipboard", vim.log.levels.INFO)
end

M.cwd_diff = function(opts)
  vim.cmd("silent !" .. diff_cmd(opts) .. " | " .. ClipExecutable)

  if vim.v.shell_error ~= 0 then
    vim.notify("git diff failed", vim.log.levels.ERROR)
    return
  end

  vim.notify("Cwd Git diff copied to clipboard", vim.log.levels.INFO)
end

M.qf_list = function(opts)
  local qflist = vim.fn.getqflist()

  if #qflist == 0 then
    vim.notify("Quickfix list is empty", vim.log.levels.WARN)
    return
  end

  local seen = {}
  local files = {}

  for _, item in ipairs(qflist) do
    if item.bufnr and item.bufnr > 0 then
      local name = vim.api.nvim_buf_get_name(item.bufnr)
      if name ~= "" and not seen[name] then
        seen[name] = true
        table.insert(files, vim.fn.fnameescape(name))
      end
    end
  end

  if #files == 0 then
    vim.notify("No valid files in quickfix list", vim.log.levels.WARN)
    return
  end

  vim.cmd(
    "silent !" .. diff_cmd(opts) .. " -- " .. table.concat(files, " ") .. " | " .. ClipExecutable
  )

  if vim.v.shell_error ~= 0 then
    vim.notify("git diff failed for quickfix files", vim.log.levels.ERROR)
    return
  end

  vim.notify(
    "Git diff for " .. #files .. " quickfix file(s) copied to clipboard",
    vim.log.levels.INFO
  )
end

return M
