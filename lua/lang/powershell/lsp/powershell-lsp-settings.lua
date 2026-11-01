local M = {}

--- Push the full buffer text to powershell_es so its copy matches nvim's. Call right before
--- formatting: after `:e` the server's copy can be stale and format edits would revert the file.
function M.sync_buffer(bufnr)
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = "powershell_es" })) do
    local ver = (vim.lsp.util.buf_versions[bufnr] or 0) + 1
    vim.lsp.util.buf_versions[bufnr] = ver
    c:notify("textDocument/didChange", {
      textDocument = { uri = vim.uri_from_bufnr(bufnr), version = ver },
      contentChanges = {
        { text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n") .. "\n" },
      },
    })
  end
end

M.powershell_es = {
  cmd = {
    "pwsh",
    "-NoLogo",
    "-NoProfile",
    "-Command",
    "&'"
      .. vim.fn.stdpath("data")
      .. "/mason/packages/powershell-editor-services/PowerShellEditorServices/Start-EditorServices.ps1' "
      .. "-Stdio "
      .. "-LogLevel Warning " -- required: script errors on $null LogLevel and exits
      .. "-HostName nvim -HostProfileId 0 -HostVersion 1.0.0 "
      .. "-SessionDetailsPath '"
      .. vim.fn.stdpath("cache")
      .. "/powershell-es/PowerShellEditorServices.json'",
  },
  settings = {
    powershell = {
      scriptAnalysis = { enable = true },
      codeFormatting = { preset = "OTBS" },
    },
  },
  --- @diagnostic disable-next-line: unused-local
  on_attach = function(client, bufnr)
    client.server_capabilities.semanticTokensProvider = nil -- conflict with tokyyo-night ?
    -- vim.notify("PowerShell LSP attached", vim.log.levels.INFO)
  end,
}

return M
