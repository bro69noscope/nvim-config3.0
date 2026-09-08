local M = {}

local op_yank_start_view = nil

local function get_file_header()
  local path = vim.fn.expand("%:p")
  if path == "" then
    return "[No file name]\n\n"
  end
  return path .. "\n\n"
end

local function count_lines(str)
  return select(2, string.gsub(str, "\n", "\n")) + 1
end

local function get_qf_files()
  local qflist = vim.fn.getqflist()
  local files, seen = {}, {}
  for _, item in ipairs(qflist) do
    local fname
    if item.bufnr and item.bufnr > 0 then
      fname = vim.api.nvim_buf_get_name(item.bufnr)
    elseif item.filename and item.filename ~= "" then
      fname = item.filename
    end
    if fname and fname ~= "" and not seen[fname] then
      seen[fname] = true
      table.insert(files, fname)
    end
  end
  return files
end

local function notify_register_update(lines_added, total_lines, preface)
  vim.notify(
    string.format(
      '%sAdded %d %s to "+ \nTotal lines: %d',
      preface and (preface .. "\n") or "",
      lines_added,
      lines_added == 1 and "line" or "lines",
      total_lines
    ),
    vim.log.levels.INFO,
    { title = "Register Update" }
  )
end

M.yank_silently = function(cmd)
  _G.Suppress_reg_feedback = true
  vim.cmd("silent " .. cmd)
  _G.Suppress_reg_feedback = false
end

M.copy_file_to_system_register = function()
  local view = vim.fn.winsaveview()
  M.yank_silently('normal! ggVG"+y')
  vim.fn.winrestview(view)
  vim.notify('Copied file content to "+', vim.log.levels.INFO, { title = "Clipboard" })
end

M.append_file_to_system_register = function()
  local reg = Scratch_registers[1]
  local view = vim.fn.winsaveview()
  M.yank_silently('normal! ggVG"' .. reg .. "y")
  vim.fn.winrestview(view)
  local system_register = vim.fn.getreg("+")
  local scratch_register = vim.fn.getreg(reg)
  local new_register_content = system_register .. scratch_register
  vim.fn.setreg("+", new_register_content)

  notify_register_update(
    count_lines(scratch_register),
    count_lines(new_register_content),
    'Appended file content to "+'
  )
end

M.copy_code_to_system_register = function()
  local view = vim.fn.winsaveview()
  M.yank_silently('normal! ggVG"+y')
  local content = vim.fn.getreg("+")
  vim.fn.setreg("+", get_file_header() .. content)
  vim.fn.winrestview(view)
  vim.notify('Copied file content and path to "+', vim.log.levels.INFO, { title = "Clipboard" })
end

M.append_code_to_system_register = function()
  local reg = Scratch_registers[1]
  local view = vim.fn.winsaveview()
  M.yank_silently('normal! ggVG"' .. reg .. "y")
  local scratch_register = vim.fn.getreg(reg)
  local system_register = vim.fn.getreg("+")
  local addition = get_file_header() .. scratch_register
  local new_register_content = system_register .. "\n\n" .. addition
  vim.fn.setreg("+", new_register_content)
  vim.fn.winrestview(view)

  notify_register_update(
    count_lines(scratch_register),
    count_lines(new_register_content),
    'Appended file content and path to "+'
  )
end

-- Visual-mode only: yanks the current selection
M.append_yank_to_system_reg_visual = function()
  local reg = Scratch_registers[1]
  M.yank_silently('normal! "' .. reg .. "y")

  local yanked = vim.fn.getreg(reg)
  local system_register = vim.fn.getreg("+")
  local new_register_content = system_register .. "\n" .. yanked
  vim.fn.setreg("+", new_register_content)

  notify_register_update(count_lines(yanked), count_lines(new_register_content))
end

-- Normal-mode only: operator-pending, works with motions/text-objects
M.append_yank_to_system_reg_op = function(motion_type)
  local reg = Scratch_registers[1]

  if motion_type == nil then
    op_yank_start_view = vim.fn.winsaveview()
    vim.o.operatorfunc =
      "v:lua.require'scripts.utils.clipboard-functions'.append_yank_to_system_reg_op"
    vim.api.nvim_feedkeys("g@", "n", false)
    return
  end

  local sel_cmd
  if motion_type == "line" then
    sel_cmd = "'[V']"
  elseif motion_type == "block" then
    sel_cmd = "`[\22`]" -- <C-v>
  else -- "char"
    sel_cmd = "`[v`]"
  end

  M.yank_silently("normal! " .. sel_cmd .. '"' .. reg .. "y")

  if op_yank_start_view then
    vim.fn.winrestview(op_yank_start_view)
    op_yank_start_view = nil
  end

  local yanked = vim.fn.getreg(reg)
  local system_register = vim.fn.getreg("+")
  local new_register_content = system_register .. "\n" .. yanked
  vim.fn.setreg("+", new_register_content)

  notify_register_update(count_lines(yanked), count_lines(new_register_content))
end

M.copy_qf_code_to_register = function()
  local files = get_qf_files()
  if #files == 0 then
    vim.notify("Quickfix list is empty", vim.log.levels.WARN, { title = "Clipboard" })
    return
  end
  local orig_buf = vim.api.nvim_get_current_buf()
  for i, fname in ipairs(files) do
    local bufnr = vim.fn.bufadd(fname)
    vim.fn.bufload(bufnr)
    vim.api.nvim_set_current_buf(bufnr)
    if i == 1 then
      M.copy_code_to_system_register()
    else
      M.append_code_to_system_register()
    end
  end
  vim.api.nvim_set_current_buf(orig_buf)
end

M.append_qf_code_to_register = function()
  local files = get_qf_files()
  if #files == 0 then
    vim.notify("Quickfix list is empty", vim.log.levels.WARN, { title = "Clipboard" })
    return
  end
  local orig_buf = vim.api.nvim_get_current_buf()
  for _, fname in ipairs(files) do
    local bufnr = vim.fn.bufadd(fname)
    vim.fn.bufload(bufnr)
    vim.api.nvim_set_current_buf(bufnr)
    M.append_code_to_system_register()
  end
  vim.api.nvim_set_current_buf(orig_buf)
end

return M
