local M = {}

M.convert_path_separators = function()
  -- Get content from unnamed register (last yank/delete)
  local content = vim.fn.getreg('"')

  -- Check if register is empty
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
    vim.notify(
      'Result copied to "" register',
      vim.log.levels.INFO,
      { title = "Path Separator Converter" }
    )
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
