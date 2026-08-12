local map = require("scripts.ui.whichkey-map").map

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
    vim.diagnostic.jump({
      count = vim.v.count1,
      severity = vim.diagnostic.severity.ERROR,
      float = true,
    })
  end

  local function prev_error()
    vim.diagnostic.jump({
      count = -vim.v.count1,
      severity = vim.diagnostic.severity.ERROR,
      float = true,
    })
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
    if client.name ~= "copilot" then
      local config = client.config
      local is_match = config and config.filetypes and vim.tbl_contains(config.filetypes, ft)
      if is_match then
        table.insert(candidates, client)
      end
    end
  end

  if #candidates == 0 then
    vim.notify("No language LSP attached for this buffer", vim.log.levels.INFO)
    return
  end

  local function do_restart(client)
    vim.cmd("lsp restart " .. client.name)
    vim.notify("Restarted LSP: " .. client.name, vim.log.levels.INFO)
  end

  if #candidates == 1 then
    do_restart(candidates[1])
  else
    vim.ui.select(candidates, {
      prompt = "Multiple language LSPs found",
      format_item = function(c)
        return c.name
      end,
    }, function(client)
      if client then
        do_restart(client)
      end
    end)
  end
end

-- LSP keymaps
local next_diag, prev_diag, next_error, prev_error = setup_diagnostic_jumps()
map("n", "]d", next_diag, { desc = "Next Diagnostic", icon = { icon = "⚠️", color = "" } })
map("n", "[d", prev_diag, { desc = "Previous Diagnostic", icon = "⚠️" })
map(
  "n",
  "]D",
  next_error,
  { desc = "Next Error Diagnostic", icon = { icon = "", color = "red" } }
)
map(
  "n",
  "[D",
  prev_error,
  { desc = "Previous Error Diagnostic", icon = { icon = "", color = "red" } }
)

map("n", "<leader>lL", function()
  vim.cmd("tabnew")
  vim.cmd("edit " .. vim.lsp.get_log_path())
end, { desc = "Open LSP log" })

map("n", "<space>ca", function()
  vim.lsp.buf.code_action({
    filter = code_action_filter,
  })
end, { desc = "code action (no bloat 🤡)" })

map("n", "<space>cA", function()
  vim.lsp.buf.code_action()
end, { desc = "code action (all)" })

map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol under cursor" })
map("n", "go", vim.diagnostic.open_float, { desc = "Open Diagnostic Float" })
map("n", "<leader>lr", restart_lsp, { desc = "Restart LSP" })
map("n", "<leader>li", "<cmd>checkhealth vim.lsp<cr>", { desc = "Show LSP info" })

-- HACK: START: Hide lualine winbar when showing hover docs, since the automatic redrawing of the
-- winbar is buggy and can cause a displacement of 1 line in the noice lsp hover window.
local function hover_with_blank_winbar()
  require("lualine").hide({ place = { "winbar" } })
  vim.lsp.buf.hover()
end

map("n", "K", hover_with_blank_winbar, { desc = "LSP Hover (winbar blanked)" })

vim.api.nvim_create_autocmd("WinClosed", {
  callback = function(args)
    local win = tonumber(args.match)
    local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
    if ok and vim.bo[buf].filetype == "noice" then
      require("lualine").hide({ place = { "winbar" }, unhide = true })
    end
  end,
})
-- HACK: END
