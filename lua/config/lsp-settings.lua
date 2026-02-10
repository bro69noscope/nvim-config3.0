-- General diagnostic settings
vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    show_header = true,
    source = "if_many",
    border = "rounded",
  },
})

-- Save after sucessful global renames to avoid issues with unsaved symbol names resetting upon sequential lsp renames
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function()
    local original_rename_handler = vim.lsp.handlers["textDocument/rename"]

    -- Override handler to save after successful rename
    vim.lsp.handlers["textDocument/rename"] = function(err, result, ctx, config)
      original_rename_handler(err, result, ctx, config)
      if result and (result.changes or result.documentChanges) then
        vim.defer_fn(function()
          vim.cmd("silent! wa")
        end, 0)
      end
    end
  end,
})

-- Filter code actions to remove non-context specific ones (auto-fixes, etc.)
local code_action_filter = function(action)
  local title = action.title:lower()

  local ruff_exclusions = {
    "ruff.*fix all",
    "ruff.*organize imports",
    "fix all.*ruff",
    "organize imports.*ruff",
  }

  for _, pattern in ipairs(ruff_exclusions) do
    if string.match(title, pattern) then
      return false
    end
  end

  return true
end

local function setup_diagnostic_jumps()
  -- Regular diagnostic jumps
  local function next_diag()
    vim.diagnostic.jump({ count = vim.v.count1, float = true })
  end

  local function prev_diag()
    vim.diagnostic.jump({ count = -vim.v.count1, float = true })
  end

  -- Error-only diagnostic jumps
  local function next_error()
    vim.diagnostic.jump({ count = vim.v.count1, severity = vim.diagnostic.severity.ERROR, float = true })
  end

  local function prev_error()
    vim.diagnostic.jump({ count = -vim.v.count1, severity = vim.diagnostic.severity.ERROR, float = true })
  end

  local next_d, prev_d = RepeatablePairs.track_pair(next_diag, prev_diag)
  local next_e, prev_e = RepeatablePairs.track_pair(next_error, prev_error)

  return next_d, prev_d, next_e, prev_e
end

local function restart_lsp()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local candidates = {}

  for _, client in ipairs(clients) do
    if
      client.name ~= "copilot"
      and client.config
      and client.config.filetypes
      and vim.tbl_contains(client.config.filetypes, ft)
    then
      table.insert(candidates, client)
    end
  end

  if #candidates == 0 then
    vim.notify("No language LSP attached for this buffer", vim.log.levels.INFO)
    return
  end

  if #candidates == 1 then
    local client = candidates[1]
    vim.lsp.stop_client(client.id)
    vim.cmd("LspStart " .. client.name)
    vim.notify("Restarted LSP: " .. client.name, vim.log.levels.INFO)
    return
  end

  -- multiple language servers match → let user choose
  vim.ui.select(candidates, {
    prompt = "Multiple language LSPs found",
    format_item = function(c)
      return c.name
    end,
  }, function(client)
    if client then
      vim.lsp.stop_client(client.id)
      vim.cmd("LspStart " .. client.name)
      vim.notify("Restarted LSP: " .. client.name, vim.log.levels.INFO)
    end
  end)
end

-- LSP keymaps
local next_diag, prev_diag, next_error, prev_error = setup_diagnostic_jumps()
vim.keymap.set("n", "]d", next_diag)
vim.keymap.set("n", "[d", prev_diag)
vim.keymap.set("n", "]D", next_error)
vim.keymap.set("n", "[D", prev_error)

vim.keymap.set("n", "<leader>xl", function()
  vim.diagnostic.config({
    virtual_text = not vim.diagnostic.config().virtual_text,
  })
end, { desc = "Toggle line diagnostics" })

vim.keymap.set("n", "<leader>xu", function()
  vim.diagnostic.config({
    underline = not vim.diagnostic.config().underline,
  })
end, { desc = "Toggle diagnostics underlines" })

vim.keymap.set("n", "K", function()
  vim.lsp.buf.hover()
end, { desc = "Lsp Hover Info" })

vim.keymap.set("n", "<space>ca", function()
  vim.lsp.buf.code_action({
    filter = code_action_filter,
  })
end, { desc = "code action (no bloat 🤡)" })

vim.keymap.set("n", "<space>cA", function()
  vim.lsp.buf.code_action()
end, { desc = "code action (all)" })

vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol under cursor" })
vim.keymap.set("n", "go", vim.diagnostic.open_float, { desc = "Open Diagnostic Float" })
vim.keymap.set("n", "<leader>lr", restart_lsp, { desc = "Restart LSP" })
