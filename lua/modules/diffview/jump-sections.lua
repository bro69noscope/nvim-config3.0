local M = {}
M.jump_to_next_section = function()
  local view = require("diffview.lib").get_current_view()
  if not view or not view.panel then
    return
  end

  local panel = view.panel
  local conf = require("diffview.config").get_config()
  local always_show = conf.file_panel.always_show_sections
  local has_other_files = #panel.files.conflicting > 0 or #panel.files.staged > 0

  local visible = {
    working = #panel.files.working > 0 or not has_other_files or always_show,
    staged = #panel.files.staged > 0 or always_show,
  }

  local sections = {}
  for _, name in ipairs({ "working", "staged" }) do
    if visible[name] then
      local comp = panel.components[name].title.comp
      if comp.lstart >= 0 then
        table.insert(sections, comp.lstart)
      end
    end
  end

  if #sections == 0 then
    return
  end
  table.sort(sections)

  panel:focus() -- opens the panel if closed, moves current window to it

  local cur_line = vim.api.nvim_win_get_cursor(panel.winid)[1] - 1
  local target = sections[1] -- wrap to first

  for _, lstart in ipairs(sections) do
    if lstart > cur_line then
      target = lstart
      break
    end
  end

  local line_count = vim.api.nvim_buf_line_count(panel.bufid)
  target = math.min(target, line_count - 1)

  vim.api.nvim_win_set_cursor(panel.winid, { target + 1, 0 })
end
return M
