local M = {}

local TYPE_CHECKING_STANDARD = 'typeCheckingMode = "standard"'
local TYPE_CHECKING_RECOMMENDED = 'typeCheckingMode = "recommended"'
local SELECT_ALL = 'select = ["ALL"]'

local function type_checking_line(normal)
  return normal and TYPE_CHECKING_STANDARD or TYPE_CHECKING_RECOMMENDED
end

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

function M.is_currently_normal(toml_path)
  local lines = vim.fn.readfile(toml_path)
  for _, line in ipairs(lines) do
    if line:match(TYPE_CHECKING_STANDARD) then
      return true
    end
  end
  return false
end

local function insert_after_section(lines, section_pattern, new_line)
  for i, line in ipairs(lines) do
    if line:match(section_pattern) then
      table.insert(lines, i + 1, new_line)
      return true
    end
  end
  vim.notify("Section " .. section_pattern .. " not found in pyproject.toml", vim.log.levels.WARN)
  return false
end

function M.set_lsp_strictness(normal)
  local toml_path = M.find_pyproject()
  if not toml_path then
    vim.notify("pyproject.toml not found", vim.log.levels.ERROR)
    return
  end

  local lines = vim.fn.readfile(toml_path)
  local found_type_checking = false
  local found_select = false
  local new_lines = {}

  for _, line in ipairs(lines) do
    if line:match("typeCheckingMode") then
      table.insert(new_lines, type_checking_line(normal))
      found_type_checking = true
    elseif line:match("^%s*select%s*=") then
      found_select = true
      if not normal then
        table.insert(new_lines, SELECT_ALL)
      end
    else
      table.insert(new_lines, line)
    end
  end

  if not found_type_checking then
    insert_after_section(new_lines, "^%[tool%.basedpyright%]", type_checking_line(normal))
  end

  if not found_select and not normal then
    insert_after_section(new_lines, "^%[tool%.ruff%.lint%]", SELECT_ALL)
  end

  vim.fn.writefile(new_lines, toml_path)
  restart_clients({ "basedpyright", "ruff" })
end

return M
