-- NOTE: unreviewed ai code
local M = {}

-- Returns the CURRENT visual selection as { lines, replace_fn }, or nil when not in visual
-- mode (replace_fn nil if unsupported, e.g. blockwise)
local function get_visual_selection()
  local vmode = vim.fn.mode()
  if not vmode:match("^[vV\22]") then
    return nil
  end
  local spos, epos = vim.fn.getpos("v"), vim.fn.getpos(".")
  -- selection may be made backwards
  if spos[2] > epos[2] or (spos[2] == epos[2] and spos[3] > epos[3]) then
    spos, epos = epos, spos
  end
  local src_buf = vim.api.nvim_get_current_buf()
  local lines = vim.fn.getregion(spos, epos, { type = vmode })
  if #lines == 0 then
    return nil
  end
  -- leave visual mode so the float opens from normal mode
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)

  local replace_fn
  if vmode == "V" then
    replace_fn = function(new_lines)
      vim.api.nvim_buf_set_lines(src_buf, spos[2] - 1, epos[2], false, new_lines)
    end
  elseif vmode == "v" then
    local last = vim.api.nvim_buf_get_lines(src_buf, epos[2] - 1, epos[2], false)[1] or ""
    local ecol = math.min(epos[3], #last)
    -- include the full (possibly multibyte) last character
    local end_col = ecol - 1 + #vim.fn.strcharpart(last:sub(ecol), 0, 1)
    replace_fn = function(new_lines)
      vim.api.nvim_buf_set_text(src_buf, spos[2] - 1, spos[3] - 1, epos[2] - 1, end_col, new_lines)
    end
  end
  return { lines = lines, replace_fn = replace_fn }
end

-- In visual mode: operate on the current selection. Otherwise: the unnamed register.
M.convert_path_separators = function()
  local selection = get_visual_selection()
  local content

  if selection then
    content = table.concat(selection.lines, "\n")
  else
    -- Get content from unnamed register (last yank/delete)
    content = vim.fn.getreg('"')
  end

  -- Check if content is empty
  if content == "" then
    vim.notify("Empty register! Copy/cut some text first.", vim.log.levels.WARN)
    return
  end

  -- Create a small scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer content
  local multilines_content = vim.split(content, "\n")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, multilines_content)

  -- Create a small floating window
  local width = math.min(75, vim.o.columns - 4)
  local height = 3
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
    title = " Path Separator Converter, 1: from \\ to /, 2: from / to \\, 3: from \\ to \\\\ , 4: custom ",
    title_pos = "center",
  })

  -- Set buffer options
  vim.bo[buf].modifiable = true
  vim.bo[buf].buftype = "nofile"

  local opts = { buffer = buf, nowait = true, silent = true }

  -- Applies `transform_fn` to every line in the buffer, then notifies with `msg`
  local function apply_transform(transform_fn, msg)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local converted = {}
    for i, line in ipairs(lines) do
      converted[i] = transform_fn(line)
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, converted)
    vim.notify(msg)
  end

  vim.keymap.set("n", "1", function()
    apply_transform(function(line)
      return line:gsub("\\", "/")
    end, "Converted \\ to /")
  end, opts)

  vim.keymap.set("n", "2", function()
    apply_transform(function(line)
      return line:gsub("/", "\\")
    end, "Converted / to \\")
  end, opts)

  vim.keymap.set("n", "3", function()
    apply_transform(function(line)
      return line:gsub("\\", "\\\\")
    end, "Converted \\ to \\\\")
  end, opts)

  vim.keymap.set("n", "4", function()
    vim.ui.input({ prompt = "From character: " }, function(from_char)
      if not from_char or from_char == "" then
        return
      end
      vim.ui.input({ prompt = "To character: " }, function(to_char)
        if not to_char or to_char == "" then
          return
        end
        local escaped_from = from_char:gsub("([%.%+%-%*%?%[%]%^%$%(%)%%])", "%%%1")
        apply_transform(function(line)
          return line:gsub(escaped_from, to_char)
        end, string.format("Converted '%s' to '%s'", from_char, to_char))
      end)
    end)
  end, opts)

  -- CR to copy result and close
  vim.keymap.set("n", "<CR>", function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    vim.fn.setreg('"', table.concat(lines, "\n"))
    vim.api.nvim_win_close(win, true)
    local msg = 'Result copied to "" register'
    if selection and selection.replace_fn then
      selection.replace_fn(lines)
      msg = 'Selection replaced, result also in "" register'
    end
    vim.notify(msg, vim.log.levels.INFO, { title = "Path Separator Converter" })
  end, opts)

  local function close_window()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.notify(
      "closed without changes",
      vim.log.levels.INFO,
      { title = "Path Separator Converter" }
    )
  end

  vim.keymap.set("n", "<Esc>", close_window, opts)
  vim.keymap.set("n", "q", close_window, opts)

  -- Auto-close when leaving buffer
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })
end

return M
