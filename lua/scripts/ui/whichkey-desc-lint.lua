--- Show a warning diagnostic when a keymap `desc` is too long
--- This is to ensure having at least 3 columns of which-key ui for keymaps
local M = {}

local MAX_DESC = 30
local ns = vim.api.nvim_create_namespace("whichkey-desc-lint")

-- Match: { ..., desc = "<text>", ... } in any table
-- (map() options, vim.keymap.set() options, lazy `keys` specs, which-key specs)
local query = vim.treesitter.query.parse(
  "lua",
  [[
  (field
    name: (identifier) @key (#eq? @key "desc")
    value: (string content: (string_content) @desc))
  ]]
)

--- Do a check only in this config (main checkout or worktree)
---@param buf integer
---@return boolean
local function in_config(buf)
  local root = vim.fs.root(buf, "init.lua")
  return root ~= nil and vim.uv.fs_stat(root .. "/lua/scripts/ui/whichkey-desc-lint.lua") ~= nil
end

-- Calls that take keymap options as a table argument
local KEYMAP_CALLS = { "map", "keymap.set", "set_keymap" }

--- Return true when the desc is part of a keymap definition:
--- - a spec with a positional entry: { "<lhs>", <rhs>, desc = ... } (lazy keys, which-key, snacks keys)
--- - the options of a keymap call: map(<mode>, <lhs>, <rhs>, { desc = ... })
--- Other tables (autocmd options, marks, dashboard items) have no positional entry and are not checked.
---@param desc_node TSNode
---@param buf integer
---@return boolean
local function is_keymap_desc(desc_node, buf)
  -- string_content > string > field > table_constructor
  local tbl = desc_node:parent():parent():parent()
  if not tbl or tbl:type() ~= "table_constructor" then
    return false
  end

  for field in tbl:iter_children() do
    if field:type() == "field" and not field:field("name")[1] then
      return true
    end
  end

  -- table_constructor > arguments > function_call
  local call = tbl:parent() and tbl:parent():parent()
  if not call or call:type() ~= "function_call" then
    return false
  end

  local name = vim.treesitter.get_node_text(call:field("name")[1], buf)
  for _, keymap_call in ipairs(KEYMAP_CALLS) do
    if
      name == keymap_call
      or vim.endswith(name, "." .. keymap_call)
      or vim.endswith(name, "_" .. keymap_call)
    then
      return true
    end
  end

  return false
end

---@param buf integer
M.lint = function(buf)
  vim.diagnostic.reset(ns, buf)
  if not in_config(buf) then
    return
  end

  local ok, parser = pcall(vim.treesitter.get_parser, buf, "lua")
  if not ok or not parser then
    return
  end

  local root = parser:parse()[1]:root()
  local diagnostics = {}

  for id, node in query:iter_captures(root, buf) do
    if query.captures[id] == "desc" and is_keymap_desc(node, buf) then
      local len = vim.fn.strchars(vim.treesitter.get_node_text(node, buf))

      if len > MAX_DESC then
        local row, col, end_row, end_col = node:range()
        table.insert(diagnostics, {
          lnum = row,
          col = col,
          end_lnum = end_row,
          end_col = end_col,
          severity = vim.diagnostic.severity.WARN,
          source = "whichkey-map",
          message = ("desc too long to fit nicely in which-key (%d > %d)"):format(len, MAX_DESC),
        })
      end
    end
  end

  vim.diagnostic.set(ns, buf, diagnostics)
end

M.setup = function()
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave", "TextChanged" }, {
    group = vim.api.nvim_create_augroup("whichkey-desc-lint", { clear = true }),
    pattern = "*.lua",
    callback = function(args)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(args.buf) then
          M.lint(args.buf)
        end
      end)
    end,
  })
end

return M
