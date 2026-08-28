local M = {}
local persist_flags = require("modules.snacks.picker.persist-flags")

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

local function watch_close(explorer)
  local win_id = explorer.layout
    and explorer.layout.wins
    and explorer.layout.wins.list
    and explorer.layout.wins.list.win
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
  local merged = apply_opts(opts)
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

    -- follow state changed: has to be rebuilt
    existing:close()
  end

  require("snacks").explorer(merged)

  vim.schedule(function()
    local explorer = Snacks.picker.get({ source = "explorer" })[1]
    if explorer then
      watch_close(explorer)
    end
  end)
end

return M
