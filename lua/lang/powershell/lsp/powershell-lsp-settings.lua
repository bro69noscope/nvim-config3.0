local M = {}

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
