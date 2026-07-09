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
    title = " Path Separator Converter, 1: from \\ to /, 2: from / to \\, 3: custom ",
    title_pos = "center",
  })

  -- /home/avario/dotfiles/nvim-config3.0/lua/plugins/snacks.lua

  -- Set buffer options
  vim.bo[buf].modifiable = true
  vim.bo[buf].buftype = "nofile"

  -- Set up key mappings for the buffer
  local opts = { buffer = buf, nowait = true, silent = true }

  -- Option 1: \ to /
  vim.keymap.set("n", "1", function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local converted = {}
    for _, line in ipairs(lines) do
      converted[#converted + 1] = line:gsub("\\", "/")
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, converted)
    vim.notify("Converted \\ to /")
  end, opts)

  -- Option 2: / to \
  vim.keymap.set("n", "2", function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local converted = {}
    for _, line in ipairs(lines) do
      converted[#converted + 1] = line:gsub("/", "\\")
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, converted)
    vim.notify("Converted / to \\")
  end, opts)

  -- Option 3: Custom conversion
  vim.keymap.set("n", "3", function()
    vim.ui.input({ prompt = "From character: " }, function(from_char)
      if not from_char or from_char == "" then
        return
      end
      vim.ui.input({ prompt = "To character: " }, function(to_char)
        if not to_char or to_char == "" then
          return
        end

        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local converted = {}
        for _, line in ipairs(lines) do
          -- Escape special regex characters
          local escaped_from = from_char:gsub("([%.%+%-%*%?%[%]%^%$%(%)%%])", "%%%1")
          converted[#converted + 1] = line:gsub(escaped_from, to_char)
        end
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, converted)
        vim.notify(string.format("Converted '%s' to '%s'", from_char, to_char))
      end)
    end)
  end, opts)

  -- Enter to copy result and close
  vim.keymap.set("n", "<CR>", function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local result = table.concat(lines, "\n")
    vim.fn.setreg('"', result)

    vim.api.nvim_win_close(win, true)
    vim.notify(
      'Result copied to empty "" register',
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
  -- ESC to cancel
  vim.keymap.set("n", "<Esc>", function()
    close_window()
  end, opts)

  -- q to close
  vim.keymap.set("n", "q", function()
    close_window()
  end, opts)

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
