local M = {}

---Buffers scoped to cwd, without gitignored or deleted files.
M.open = function()
  local cwd = vim.fn.getcwd()
  local files = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(b)
    if vim.bo[b].buflisted and name ~= "" then
      files[#files + 1] = vim.fs.normalize(name)
    end
  end

  local function open(ignored)
    Snacks.picker.buffers({
      title = "Buffers (cwd)",
      cwd = cwd,
      filter = { cwd = true },
      transform = function(item)
        local file = item.file
        if not file then
          return
        end
        if ignored[vim.fs.normalize(file)] or not vim.uv.fs_stat(file) then
          return false
        end
      end,
    })
  end

  -- single async git call; picker opens in callback
  vim.system(
    { "git", "-C", cwd, "check-ignore", "-z", "--stdin" },
    { stdin = table.concat(files, "\0") },
    vim.schedule_wrap(function(res)
      local ignored = {}
      for p in (res.stdout or ""):gmatch("([^%z]+)") do
        ignored[vim.fs.normalize(p)] = true
      end
      open(ignored)
    end)
  )
end

return M
