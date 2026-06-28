for _, c in ipairs({ "(", ")", "[", "]", "{", "}" }) do
  local next = function()
    vim.fn.search(vim.fn.escape(c, [[\]]), "W")
  end

  local prev = function()
    vim.fn.search(vim.fn.escape(c, [[\]]), "bW")
  end

  next, prev = RepeatablePairs.track_pair(next, prev)

  vim.keymap.set("n", "]" .. c, next, { desc = "Next " .. c })
  vim.keymap.set("n", "[" .. c, prev, { desc = "Previous " .. c })
end
