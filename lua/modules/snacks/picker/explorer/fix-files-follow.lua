-- Ensure snacks-explorer follows the current file when changing buffers. Everytime.

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("snacks_explorer_follow_file_fix", { clear = true }),
  callback = function(args)
    local bufname = vim.api.nvim_buf_get_name(args.buf)
    if bufname == "" or vim.bo[args.buf].buftype ~= "" then
      return
    end

    local explorer = Snacks.picker.get({ source = "explorer" })[1]
    if not explorer then
      return
    end

    if explorer.opts.follow_file == false then
      return
    end

    pcall(Snacks.explorer.reveal, { file = bufname })
  end,
})
