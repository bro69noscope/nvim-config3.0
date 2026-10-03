local create_return_action = function(current_win, cursor_pos, explorer, list_state)
  return function(picker)
    picker:close()
    vim.api.nvim_set_current_win(current_win)
    vim.api.nvim_win_set_cursor(current_win, cursor_pos)

    -- follow-file re-targets the list asynchronously, so re-apply afterwards
    vim.defer_fn(function()
      if explorer and not explorer.closed then
        explorer.list:view(list_state.cursor, list_state.top)
      end
    end, 10) -- couldn't get schedule to work all the time
  end
end

-- Wrapper function to launch any picker with return-to-explorer capability
return function(picker_fn, config)
  local current_win = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(current_win)
  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  local list_state = explorer and { cursor = explorer.list.cursor, top = explorer.list.top } or {}

  vim.schedule(function()
    -- Fix a visual bug that happens if we run another Snacks picker while having the Snacks
    -- explorer in focus right before their launch.
    vim.cmd("wincmd p")

    -- Merge the return action into the config
    config.actions = config.actions or {}
    config.actions.return_to_explorer =
      create_return_action(current_win, cursor_pos, explorer, list_state)

    -- Add "return with explorer in focus" escape key mapping
    config.win = config.win or {}
    config.win.input = config.win.input or {}
    config.win.input.keys = config.win.input.keys or {}
    if not config.win.input.keys["<esc>"] then
      config.win.input.keys["<esc>"] = "return_to_explorer"
    else
      vim.notify(
        "Warning: <esc> key mapping detected in Snacks picker input window. "
          .. "This key is supposed to be reserved for the 'return to explorer' action.",
        vim.log.levels.WARN
      )
    end

    picker_fn(config)
  end)
end
