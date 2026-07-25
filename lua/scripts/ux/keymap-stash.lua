-- lua/scripts/ux/keymap-stash.lua
--
-- Temporarily override keymaps and restore whatever was there before,
-- including Lua-callback mappings (expr, silent, noremap, etc. preserved).
-- Useful for plugins that need to borrow a key for the duration of some
-- mode/state (e.g. vim-visual-multi borrowing <C-j>/<C-k> from blink.cmp).
--
-- Usage:
--   stash:save("i", "<C-j>")
--   vim.keymap.set("i", "<C-j>", my_fn, { buffer = true, expr = true })
--   ...
--   stash:restore("i", "<C-j>")   -- restores single key
--   stash:restore_all()           -- or restore everything saved on this stash

local M = {}
local Stash = {}
Stash.__index = Stash

--- Create a new stash instance. Each instance keeps its own saved-map table,
--- so unrelated features (e.g. two different plugins) shouldn't share one.
function M.new()
  return setmetatable({ _maps = {} }, Stash)
end

--- Save whatever is currently mapped to `lhs` in `mode` (buffer-local aware,
--- falls back to global per Neovim's own maparg() resolution).
--- Safe to call multiple times; re-saving overwrites the stored snapshot.
function Stash:save(mode, lhs)
  local info = vim.fn.maparg(lhs, mode, false, true)

  self._maps[mode] = self._maps[mode] or {}
  if info and info.lhs and info.lhs ~= "" then
    self._maps[mode][lhs] = info
  else
    self._maps[mode][lhs] = false -- sentinel: nothing was mapped
  end
end

--- Save a batch at once: stash:save_many("i", { "<C-j>", "<C-k>" })
function Stash:save_many(mode, lhs_list)
  for _, lhs in ipairs(lhs_list) do
    self:save(mode, lhs)
  end
end

--- Restore a single previously-saved mapping. If nothing had been mapped
--- before save() was called, this just clears the current mapping instead.
function Stash:restore(mode, lhs)
  local bucket = self._maps[mode]
  local info = bucket and bucket[lhs]
  if bucket then
    bucket[lhs] = nil
  end

  if info == nil then
    -- nothing was ever saved for this key; no-op
    return
  end

  if info == false then
    pcall(vim.keymap.del, mode, lhs, { buffer = true })
    return
  end

  local rhs = info.callback or info.rhs
  vim.keymap.set(mode, lhs, rhs, {
    buffer = info.buffer == 1,
    expr = info.expr == 1,
    silent = info.silent == 1,
    noremap = info.noremap == 1,
    nowait = info.nowait == 1,
    desc = info.desc,
  })
end

--- Restore every key currently held in this stash.
function Stash:restore_all()
  -- snapshot mode/lhs pairs first since restore() mutates self._maps while iterating
  local pending = {}
  for mode, bucket in pairs(self._maps) do
    for lhs in pairs(bucket) do
      table.insert(pending, { mode, lhs })
    end
  end
  for _, pair in ipairs(pending) do
    self:restore(pair[1], pair[2])
  end
end

return M
