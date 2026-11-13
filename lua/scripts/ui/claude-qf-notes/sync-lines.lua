local M = {}

local navigate = require("scripts.ui.claude-qf-notes.navigate")

---Rewrite the `line = N,` of the notes placed in buf to the rows their extmarks are at now.
---@param buf integer
function M.sync(buf)
  local rows = {}
  local marks = vim.api.nvim_buf_get_extmarks(buf, navigate.NAMESPACE, 0, -1, {})
  if #marks == 0 then
    return
  end
  for _, m in ipairs(marks) do
    rows[m[1]] = m[2] + 1
  end

  local path = vim.fn.fnamemodify(navigate.NOTES_FILE, ":p")
  if vim.fn.filereadable(path) == 0 then
    return
  end
  local lines = vim.fn.readfile(path)
  local index = 0
  local changed = false
  for i, l in ipairs(lines) do
    if l:match("^}") then
      break
    end
    local prefix, suffix = l:match("^(%s*line = )%d+(,%s*)$")
    if prefix then
      index = index + 1
      local row = rows[index]
      if row then
        local new = prefix .. row .. suffix
        if new ~= l then
          lines[i] = new
          changed = true
        end
      end
    end
  end

  if not changed then
    return
  end
  if vim.fn.writefile(lines, path) ~= 0 then
    vim.notify("could not update " .. navigate.NOTES_FILE, vim.log.levels.WARN)
    return
  end
  -- reload the notes file if it is open, so a stale buffer is not shown or written back over it
  local notes_buf = vim.fn.bufnr(path)
  if notes_buf ~= -1 and vim.api.nvim_buf_is_loaded(notes_buf) then
    vim.cmd("checktime " .. notes_buf)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("ClaudeNotesSyncLines", { clear = true }),
    callback = function(args)
      M.sync(args.buf)
    end,
    desc = "Write the moved claude note lines back into the notes file",
  })
end

return M
