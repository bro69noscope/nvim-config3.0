local M = {}
local persist_flags = require("modules.snacks.picker.persist-flags")
local map = require("scripts.ui.whichkey-map").map

local function apply_opts(opts)
  opts = opts or {}
  local no_follow = opts.follow_file == false
  persist_flags.set("explorer", "no_follow", no_follow)

  local merged = vim.tbl_deep_extend("force", {
    hidden = persist_flags.get("explorer", "hidden", false),
    ignored = persist_flags.get("explorer", "ignored", false),
    no_follow_file = no_follow,
  }, opts)

  return merged, no_follow
end

local function get_explorer_win(explorer)
  local win_id = explorer.layout
    and explorer.layout.wins
    and explorer.layout.wins.list
    and explorer.layout.wins.list.win
  if not win_id or not vim.api.nvim_win_is_valid(win_id) then
    return nil
  end
  return win_id
end

local function capture_width(explorer)
  local win_id = get_explorer_win(explorer)
  if not win_id then
    return nil
  end
  return vim.api.nvim_win_get_width(win_id)
end

local function make_restore_width_on_show(width, base_on_show)
  -- TODO: study this a bit more
  if not width then
    return base_on_show
  end

  return function(picker, ...)
    if base_on_show then
      base_on_show(picker, ...)
    end

    local win = get_explorer_win(picker)
    if win then
      vim.api.nvim_win_set_width(win, width)
    end

    vim.defer_fn(function()
      local w = get_explorer_win(picker)
      if w and vim.api.nvim_win_is_valid(w) then
        vim.api.nvim_win_set_width(w, width)
      end
    end, 50)
  end
end

local function watch_close(explorer)
  local win_id = get_explorer_win(explorer)
  if not win_id then
    return
  end

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win_id),
    once = true,
    callback = function()
      persist_flags.set("explorer", "no_follow", false)
    end,
  })
end

M.toggle = function(opts)
  local existing = Snacks.picker.get({ source = "explorer" })[1]
  local remembered_width = existing and capture_width(existing) or nil

  local merged = apply_opts(opts)
  merged.on_show = make_restore_width_on_show(remembered_width, merged.on_show)
  require("snacks").explorer(merged)

  vim.schedule(function()
    local explorer = Snacks.picker.get({ source = "explorer" })[1]
    if explorer then
      watch_close(explorer)
    end
  end)
end

M.open = function(opts)
  local existing = Snacks.picker.get({ source = "explorer" })[1]
  local merged, no_follow = apply_opts(opts)

  if existing then
    local existing_is_no_follow = existing.opts.follow_file == false

    if existing_is_no_follow == no_follow then
      existing:focus("list")
      return
    end

    -- we have to rebuild the explorer to update the no_follow flag, no api to toggle it on the fly
    local remembered_width = capture_width(existing)
    existing:close()
    merged.on_show = make_restore_width_on_show(remembered_width, merged.on_show)
    require("snacks").explorer(merged)
  else
    require("snacks").explorer(merged)
  end

  vim.schedule(function()
    local explorer = Snacks.picker.get({ source = "explorer" })[1]
    if explorer then
      watch_close(explorer)
    end
  end)
end

map("n", "<M-R>", function()
  persist_flags.set("explorer", "hidden", false)
  persist_flags.set("explorer", "ignored", false)
  persist_flags.set("explorer", "no_follow", false)

  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  local remembered_width = explorer and capture_width(explorer) or nil
  if explorer then
    pcall(explorer.close, explorer)
  end

  local win = vim.api.nvim_get_current_win()
  M.open({
    on_show = make_restore_width_on_show(remembered_width),
  })

  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.schedule(function()
        vim.api.nvim_set_current_win(win)
      end)
    end
  end)
end, { desc = "Reset explorer flags" })

return M
