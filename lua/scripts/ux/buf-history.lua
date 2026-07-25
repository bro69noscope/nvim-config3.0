local M = {}

local mru = {} -- mru[1] = most recently used buffer
local idx = 1 -- current position while browsing history
local navigating = false -- true while we're switching buffers ourselves

local function is_listed(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
end

local function remove_buf(buf)
  for i, b in ipairs(mru) do
    if b == buf then
      table.remove(mru, i)
      return
    end
  end
end

local function on_buf_enter()
  local buf = vim.api.nvim_get_current_buf()
  if not is_listed(buf) then
    return
  end

  if navigating then
    -- keep idx in sync, but don't reorder the list
    for i, b in ipairs(mru) do
      if b == buf then
        idx = i
        break
      end
    end
    return
  end

  -- normal switch: bump to front, reset browsing position
  remove_buf(buf)
  table.insert(mru, 1, buf)
  idx = 1
end

local function on_buf_gone(args)
  remove_buf(args.buf)
  if idx > #mru then
    idx = #mru
  end
end

local function goto_idx(target)
  if #mru == 0 then
    return
  end
  target = math.max(1, math.min(target, #mru))
  local buf = mru[target]
  if not is_listed(buf) then
    remove_buf(buf)
    return
  end
  idx = target
  navigating = true
  vim.cmd("buffer " .. buf)
  navigating = false
end

--- Go further back in visit history
function M.prev()
  goto_idx(idx + 1)
end

--- Go forward again toward the most recent
function M.next()
  goto_idx(idx - 1)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("MruBufferNav", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", { group = group, callback = on_buf_enter })
  vim.api.nvim_create_autocmd(
    { "BufDelete", "BufWipeout" },
    { group = group, callback = on_buf_gone }
  )

  on_buf_enter() -- seed with whatever buffer is current at setup time

  vim.keymap.set("n", "]b", M.next, { desc = "Next MRU buffer" })
  vim.keymap.set("n", "[b", M.prev, { desc = "Previous MRU buffer" })
end

return M
