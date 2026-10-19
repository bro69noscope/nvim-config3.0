vim.api.nvim_create_autocmd("CmdwinEnter", {
  pattern = "*",
  callback = function()
    -- cmp wont work or cause visual glitches
    vim.b.completion = false
    local buf = vim.api.nvim_get_current_buf()
    local win_id = vim.api.nvim_get_current_win()

    -- quit with q
    vim.keymap.set("n", "q", "<cmd>q<cr>", { buffer = buf, silent = true })

    -- nmode CR: close cmdwin but keep its current input in the cmdline
    -- imode CR: directly execute the command/search
    vim.keymap.set("n", "<CR>", function()
      local line = vim.api.nvim_get_current_line() or ""
      local t = vim.fn.getcmdwintype()
      local prefix = (t == "?" or t == "/") and "/" or ":"
      vim.cmd("q")
      vim.api.nvim_feedkeys(prefix .. line, "n", false)
    end, { buffer = buf, silent = true })

    -- float config
    local width = 90
    vim.api.nvim_win_set_config(win_id, {
      relative = "editor",
      width = width,
      height = 15,
      col = math.floor((vim.o.columns - width) / 2 - 1),
      row = math.floor(vim.o.lines * 0.55),
      border = "rounded",
      title = " Cmdline ",
      title_pos = "center",
    })
  end,
})
