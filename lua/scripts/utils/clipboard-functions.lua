local M = {}
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

M.copy_file_to_system_register = function()
  local view = vim.fn.winsaveview()
  vim.cmd('normal! ggVG"+y')
  vim.fn.winrestview(view)
end

M.append_file_to_system_register = function()
  local view = vim.fn.winsaveview()
  vim.cmd('normal! ggVG"my')
  vim.fn.winrestview(view)
  local current_clipboard = vim.fn.getreg("+")
  local m_register = vim.fn.getreg("m")
  local new_register_content = current_clipboard .. m_register
  vim.fn.setreg("+", new_register_content)

  local lines_added = count_lines(m_register)
  local total_lines = count_lines(new_register_content)
  vim.notify(
    string.format(
      "Appended file content to system clipboard\nAdded %d %s | Total lines: %d",
      lines_added,
      lines_added == 1 and "line" or "lines",
      total_lines
    ),
    vim.log.levels.INFO,
    { title = "Clipboard" }
  )
end

M.copy_code_to_system_register = function()
  local view = vim.fn.winsaveview()
  vim.cmd('normal! ggVG"+y')
  local content = vim.fn.getreg("+")
  vim.fn.setreg("+", get_file_header() .. content)
  vim.fn.winrestview(view)
  vim.notify(
    "Copied file content to system clipboard",
    vim.log.levels.INFO,
    { title = "Clipboard" }
  )
end

M.append_code_to_system_register = function()
  local view = vim.fn.winsaveview()
  vim.cmd('normal! ggVG"my')
  local m_register = vim.fn.getreg("m")
  local current_clipboard = vim.fn.getreg("+")
  local addition = get_file_header() .. m_register
  local new_register_content = current_clipboard .. "\n\n" .. addition
  vim.fn.setreg("+", new_register_content)
  vim.fn.winrestview(view)

  local lines_added = count_lines(m_register)
  local total_lines = count_lines(new_register_content)
  vim.notify(
    string.format(
      "Appended file content to system clipboard\nAdded %d %s | Total lines: %d",
      lines_added,
      lines_added == 1 and "line" or "lines",
      total_lines
    ),
    vim.log.levels.INFO,
    { title = "Clipboard" }
  )
end

M.append_unnamed_reg_to_system_reg = function()
  local unnamed_register = vim.fn.getreg('"')
  local system_register = vim.fn.getreg("+")
  local new_register_content = system_register .. "\n" .. unnamed_register
  vim.fn.setreg("+", new_register_content)

  local lines_added = count_lines(unnamed_register)
  local total_lines = count_lines(new_register_content)
  vim.notify(
    string.format(
      "Added %d %s to system register\nTotal lines: %d",
      lines_added,
      lines_added == 1 and "line" or "lines",
      total_lines
    ),
    vim.log.levels.INFO,
    { title = "Register Update" }
  )
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
