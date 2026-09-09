-- go to next/prev ALLCAPS words in python files, load with schedule to override existing keymaps
-- from treesitter-textobjects
local buf = vim.api.nvim_get_current_buf()

vim.schedule(function()
  local repeatable_pairs = require("config.repeatable-pairs")

  local next_constant, prev_constant = repeatable_pairs.track_pair(function()
    vim.fn.search([[\<[A-Z][A-Z0-9_]*\>\s*=]], "")
  end, function()
    vim.fn.search([[\<[A-Z][A-Z0-9_]*\>\s*=]], "b")
  end)

  vim.keymap.set("n", "]k", next_constant, { desc = "Next .py constant", buffer = buf })
  vim.keymap.set("n", "[k", prev_constant, { desc = "Previous .py constant", buffer = buf })

  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({
      { "]k", desc = "Next .py constant", buffer = buf },
      { "[k", desc = "Previous .py constant", buffer = buf },
    })
  end
end)
