local M = {}

local default_wrap_state = vim.o.wrap

-- Remember the wrap setting so it can be restored when diffview closes
M.save_wrap_state = function()
  default_wrap_state = vim.o.wrap
end

M.setup = function()
  vim.api.nvim_create_autocmd("User", {
    pattern = "DiffviewClose",
    callback = function()
      vim.o.wrap = default_wrap_state
    end,
  })

  -- fix powershell_es lsp attaching to diffview buffers (again lol)
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local bufnr = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local name = vim.api.nvim_buf_get_name(bufnr)

      if client and client.name == "powershell_es" and name:match("^diffview://") then
        vim.schedule(function()
          vim.lsp.buf_detach_client(bufnr, client.id)
        end)
      end
    end,
  })
end

return M
