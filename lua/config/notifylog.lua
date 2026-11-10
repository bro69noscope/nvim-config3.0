--- A popup that is also written to the Logger file. Use it for what the user must see (errors,
--- warnings to act on, final results); call Logger directly for progress and other detail.
local M = {}

---@class NotifyLogOpts
---@field title? string popup title
---@field ctx? string Logger context tag, shown as [ctx] in the log

---@param msg string
---@param level? integer vim.log.levels.*, defaults to INFO
---@param opts? NotifyLogOpts
function M.notify(msg, level, opts)
  opts = opts or {}
  level = level or vim.log.levels.INFO
  if level >= vim.log.levels.ERROR then
    Logger.error(msg, opts.ctx)
  elseif level >= vim.log.levels.WARN then
    Logger.warn(msg, opts.ctx)
  else
    Logger.info(msg, opts.ctx)
  end
  vim.notify(msg, level, { title = opts.title })
end

--- A notify(msg, level) with title and ctx already filled in, so a module sets them once.
---@param opts NotifyLogOpts
---@return fun(msg: string, level?: integer)
function M.bind(opts)
  return function(msg, level)
    M.notify(msg, level, opts)
  end
end

return M
