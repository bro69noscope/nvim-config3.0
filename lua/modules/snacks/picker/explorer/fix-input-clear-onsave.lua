-- Ensure a stable snapshot of snacks-explorer when set in "no file follow" that remains even when
-- moving the focus away from the explorer and editing files.
local saved_input = nil

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("snacks_explorer_preserve_input", { clear = true }),
  callback = function()
    local explorer = Snacks.picker.get({ source = "explorer" })[1]
    if not explorer then
      return
    end
    saved_input = explorer.input.filter and explorer.input.filter.pattern
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = "snacks_explorer_preserve_input",
  callback = function()
    if not saved_input or saved_input == "" then
      saved_input = nil
      return
    end

    vim.schedule(function()
      local explorer = Snacks.picker.get({ source = "explorer" })[1]
      if not explorer then
        saved_input = nil
        return
      end

      local buf = explorer.input.win and explorer.input.win.buf
      if buf and vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { saved_input })
        if explorer.input.filter then
          explorer.input.filter.pattern = saved_input
        end
        explorer:find()
      end

      saved_input = nil
    end)
  end,
})
