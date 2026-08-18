local M = {}

local function trigger_edit_on_attach(buf)
  local augroup = vim.api.nvim_create_augroup("TriggerRuffDiagnostics_" .. buf, { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = augroup,
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modifiable then
          vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, { "" })
          vim.bo[buf].modified = false
        end
      end)
    end,
  })
end

local function normalize_path(path)
  return path:gsub("\\", "/")
end

M.open_buffers = function()
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  local git_root_name = vim.fn.fnamemodify(git_root, ":t")
  local default_dir = git_root or vim.fn.getcwd()
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir = vim.fn.fnamemodify(current_file, ":h")
  local current_relative_dir = ""

  if git_root and vim.startswith(current_dir, git_root) then
    current_relative_dir = current_dir:sub(#git_root + 2)
  end

  -- change cwd to get relative paths completions
  local old_cwd = vim.fn.getcwd()
  vim.fn.chdir(git_root)

  local dir = vim.fn.input({
    prompt = "Directory (relative to git root: " .. git_root_name .. ") ",
    default = current_relative_dir,
    completion = "dir",
  })

  vim.fn.chdir(old_cwd)

  if dir == "" then
    return
  end

  if not vim.startswith(dir, "/") then
    dir = default_dir .. "/" .. dir
  end

  dir = normalize_path(vim.fn.fnamemodify(dir, ":p"))

  -- Fix double slashes
  if vim.endswith(dir, "/") then
    dir = dir:sub(1, -2)
  end

  -- Get git-tracked files (returns relative to git root)
  local git_files_raw =
    vim.fn.systemlist(string.format("git -C %s ls-files", vim.fn.shellescape(git_root)))
  local git_files = {}
  for _, file in ipairs(git_files_raw) do
    local full_path = normalize_path(git_root .. "/" .. file)
    git_files[full_path] = true
  end

  local files = vim.fn.glob(dir .. "/**/*", false, true)

  local loaded = 0
  local delay = 40
  local delay_counter = 0
  local original_buf = vim.api.nvim_get_current_buf()

  for _, file in ipairs(files) do
    local normalized_file = normalize_path(file)
    if vim.fn.isdirectory(file) == 0 and git_files[normalized_file] then
      vim.defer_fn(function()
        vim.cmd("badd " .. vim.fn.fnameescape(file))
        vim.cmd("edit " .. vim.fn.fnameescape(file))
        local buf = vim.fn.bufnr(file)
        trigger_edit_on_attach(buf)
      end, delay_counter * delay)
      loaded = loaded + 1
      delay_counter = delay_counter + 1
    end
  end

  vim.defer_fn(function()
    vim.api.nvim_set_current_buf(original_buf)
    print(string.format("Loaded %d files from %s", loaded, dir))
    local ok = pcall(require, "trouble")
    if ok then
      vim.cmd("Trouble diagnostics focus=true")
    end
  end, (delay_counter + 1) * delay)
end

return M
