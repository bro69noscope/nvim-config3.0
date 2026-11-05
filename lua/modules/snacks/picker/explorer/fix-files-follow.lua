-- Ensure snacks-explorer follows the current file when changing buffers. Everytime.
local M = {}
local open_with_flags = require("modules.snacks.picker.explorer.open-with-flags")

local function reopen_explorer()
  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  if not explorer then
    return
  end

  pcall(explorer.close, explorer)
  pcall(open_with_flags.open)
  vim.defer_fn(function()
    vim.cmd("wincmd p")
  end, 20)
end

M.refresh_after_cwd_change = function()
  vim.defer_fn(reopen_explorer, 100)
end

local reveal_timer = assert(vim.uv.new_timer())
local pending_file
local last_enter = 0
local BURST_GAP_MS = 300
local TRAILING_MS = 150

local function reveal_latest()
  local file = pending_file
  pending_file = nil
  if not file then
    return
  end

  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  if not explorer or explorer.opts.follow_file == false then
    return
  end

  pcall(Snacks.explorer.reveal, { file = file })
end

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("snacks_explorer_follow_file_fix", { clear = true }),
  callback = function(args)
    if vim.g.snacks_explorer_dirchange_lock then
      return
    end

    local bufname = vim.api.nvim_buf_get_name(args.buf)
    if bufname == "" or vim.bo[args.buf].buftype ~= "" then
      return
    end

    local explorer = Snacks.picker.get({ source = "explorer" })[1]
    if not explorer then
      return
    end

    if explorer.opts.follow_file == false then
      return
    end

    local now = vim.uv.now()
    local is_burst = now - last_enter < BURST_GAP_MS
    last_enter = now

    pending_file = bufname
    reveal_timer:stop()
    if is_burst then
      reveal_timer:start(TRAILING_MS, 0, vim.schedule_wrap(reveal_latest))
    else
      vim.schedule(reveal_latest)
    end

    if vim.g.snacks_explorer_needs_cwd_refresh then
      vim.g.snacks_explorer_needs_cwd_refresh = false
      M.refresh_after_cwd_change()
    end
  end,
})

-- this introduced a regression where the explorer would not follow the current file when changing
-- cwd, so we fix this with a guard then, lol:
vim.api.nvim_create_autocmd("DirChanged", {
  group = vim.api.nvim_create_augroup("snacks_explorer_cwd_refresh", { clear = true }),
  callback = function()
    local explorer = Snacks.picker.get({ source = "explorer" })[1]
    if not explorer then
      return
    end

    vim.g.snacks_explorer_dirchange_lock = true

    vim.schedule(function()
      vim.defer_fn(function()
        vim.g.snacks_explorer_dirchange_lock = false
        vim.g.snacks_explorer_needs_cwd_refresh = true
      end, 200)
    end)
  end,
})

return M
