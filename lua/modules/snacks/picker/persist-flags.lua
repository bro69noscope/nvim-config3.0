local M = {}

local state = {}
local data_file = vim.fn.stdpath("data") .. "/modules/persist-flags.json"
local initialized = false

local function load()
  local f = io.open(data_file, "r")
  if not f then
    return {}
  end
  local content = f:read("*a")
  f:close()
  local ok, decoded = pcall(vim.json.decode, content)
  return ok and decoded or {}
end

local function save()
  local f = io.open(data_file, "w")
  if not f then
    return
  end
  f:write(vim.json.encode(state))
  f:close()
end

function M.setup()
  if initialized then
    return
  end
  vim.fn.mkdir(vim.fn.stdpath("data") .. "/modules", "p")
  state = load()
  initialized = true
end

function M.get(source, key, default)
  M.setup()
  local s = state[source]
  if s == nil or s[key] == nil then
    return default
  end
  return s[key]
end

function M.set(source, key, value)
  M.setup()
  state[source] = state[source] or {}
  state[source][key] = value
  save()
end

return M
