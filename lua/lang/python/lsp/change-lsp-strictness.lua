local M = {}

local STRICTNESS_SCRIPT = "src/scripts/lsp_strictness.py"
local BUNDLED_SCRIPT = "scripts/lsp_strictness.py" -- relative to stdpath("config")
local STRICT_MARKER = "basedpyrightconfig.json"

local function restart_clients(names)
  for _, name in ipairs(names) do
    local clients = vim.lsp.get_clients({ name = name })
    for _, client in ipairs(clients) do
      local bufs = {}
      for buf, _ in pairs(client.attached_buffers or {}) do
        table.insert(bufs, buf)
      end
      client:stop()
      vim.defer_fn(function()
        for _, buf in ipairs(bufs) do
          vim.cmd("edit " .. vim.fn.fnameescape(vim.api.nvim_buf_get_name(buf)))
        end
      end, 500)
    end
  end
end

function M.find_pyproject()
  local found = vim.fs.find("pyproject.toml", {
    upward = true,
    path = vim.api.nvim_buf_get_name(0),
  })
  return found[1]
end

-- Relaxed ("normal") = no override files; pyproject.toml applies as written.
function M.is_currently_normal(toml_path)
  local root = vim.fs.dirname(toml_path)
  return vim.uv.fs_stat(root .. "/" .. STRICT_MARKER) == nil
end

function M.set_lsp_strictness(normal)
  local toml_path = M.find_pyproject()
  if not toml_path then
    vim.notify("pyproject.toml not found", vim.log.levels.ERROR)
    return
  end

  local root = vim.fs.dirname(toml_path)
  -- Prefer the project's own copy, else the one bundled with this nvim config.
  local script = root .. "/" .. STRICTNESS_SCRIPT
  if vim.uv.fs_stat(script) == nil then
    script = vim.fn.stdpath("config") .. "/" .. BUNDLED_SCRIPT
  end
  if vim.uv.fs_stat(script) == nil then
    vim.notify(
      "lsp_strictness.py not found in " .. root .. " or the nvim config",
      vim.log.levels.ERROR
    )
    return
  end

  local python = vim.fn.executable("python3") == 1 and "python3" or "python"
  local result = vim
    .system({ python, script, normal and "relaxed" or "strict", "--root", root }, { text = true })
    :wait()
  if result.code ~= 0 then
    vim.notify("lsp_strictness failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
    return
  end

  restart_clients({ "basedpyright", "ruff" })
end

return M
