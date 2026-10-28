local M = {}

M.rescope = function(picker, scope)
  local source = picker.opts.source
  local text = picker.input:get()
  local is_live = picker.opts.live
  local hidden = picker.opts.hidden
  local ignored = picker.opts.ignored
  picker:close()
  vim.schedule(function()
    local opts = {
      title = source .. " (" .. scope .. ")",
      hidden = hidden,
      ignored = ignored,
      filter = { cwd = false },
    }
    if is_live then
      opts.search = text
    else
      opts.pattern = text
    end
    if scope == "git root" then
      opts.cwd = Snacks.git.get_root() or vim.fn.getcwd()
      opts.filter.cwd = true
    elseif scope == "cwd" then
      opts.cwd = vim.fn.getcwd()
      opts.filter.cwd = true
    end
    Snacks.picker.pick(source, opts)
  end)
end

return M
