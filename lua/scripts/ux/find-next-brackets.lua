for _, c in ipairs({ "(", ")", "[", "]", "{", "}" }) do
  local next = function()
    local found = vim.fn.search(vim.fn.escape(c, [[\]]), "W")
    if found == 0 then
      vim.notify("No next '" .. c .. "' found", vim.log.levels.WARN)
    end
  end

  local prev = function()
    local found = vim.fn.search(vim.fn.escape(c, [[\]]), "bW")
    if found == 0 then
      vim.notify("No previous '" .. c .. "' found", vim.log.levels.WARN)
    end
  end

  next, prev = RepeatablePairs.track_pair(next, prev)

  vim.keymap.set("n", "]" .. c, next, { desc = "Next " .. c })
  vim.keymap.set("n", "[" .. c, prev, { desc = "Previous " .. c })
end
