local M = {}
local python_ignore_paths = {
  -- windows (requires the drive : character)
  "*:/**/Python*/Lib/**",
  "*:/**/python*/lib/**",
  "*:/**/site-packages/**",
  -- linux (requires the / at the start)
  "/**/nvim/mason/packages/**",
  "/**/lib/python*/**",
  "/**/site-packages/**",
}
local ignore_all_paths = {
  "*:/*",
  "/*",
}

M.pylsp = {
  settings = {
    pylsp = {
      plugins = {
        pylint = {
          enabled = true,
          args = {
            "--ignore-paths=" .. table.concat(python_ignore_paths, ","),
          },
        },
        rope_rename = { enabled = false }, -- doesnt seem to do anything useful lmfao
        mccabe = { enabled = false },
        jedi_completion = { enabled = false },
        jedi_hover = { enabled = false },
        jedi_references = { enabled = false },
        jedi_signature_help = { enabled = false },
        jedi_symbols = { enabled = false },
        pycodestyle = { enabled = false },
        pydocstyle = { enabled = false },
        pyflakes = { enabled = false },
        autopep8 = { enabled = false },
        yapf = { enabled = false },
        rope_completion = { enabled = false },
        ruff = { enabled = false },
      },
    },
  },
  on_attach = function(client, _)
    client.server_capabilities.renameProvider = true
    client.server_capabilities.completionProvider = nil
    client.server_capabilities.hoverProvider = nil
    client.server_capabilities.signatureHelpProvider = nil
    client.server_capabilities.definitionProvider = nil
    client.server_capabilities.referencesProvider = nil
    client.server_capabilities.documentHighlightProvider = nil
    client.server_capabilities.documentSymbolProvider = nil
    client.server_capabilities.workspaceSymbolProvider = nil
    client.server_capabilities.codeActionProvider = nil
    client.server_capabilities.codeLensProvider = nil
    client.server_capabilities.documentFormattingProvider = nil
    client.server_capabilities.documentRangeFormattingProvider = nil
    client.server_capabilities.documentOnTypeFormattingProvider = nil
    client.server_capabilities.executeCommandProvider = nil
  end,
}

M.pyright = {
  settings = {
    python = {
      analysis = {
        ignore = ignore_all_paths, -- we use basedpyright for diagnostics
        typeCheckingMode = "off",
      },
    },
    pyright = {
      disableTaggedHints = true, -- Some cancer obscure shit, keep it disabled.
    },
  },
  on_attach = function(client, bufnr)
    client.server_capabilities.renameProvider = false -- can't rename module symbols (pylsp can)
  end,
}

M.basedpyright = {
  settings = {
    basedpyright = {
      analysis = {
        ignore = python_ignore_paths,
      },
    },
  },
  on_attach = function(client, bufnr)
    client.server_capabilities.renameProvider = false -- can't rename module symbols (pylsp can)
    -- Disable capabilities that pyright handles better/faster
    -- NOTE: now testing basedpyright for everything pyright used to do

    -- client.server_capabilities.completionProvider = false
    -- client.server_capabilities.hoverProvider = false
    -- client.server_capabilities.signatureHelpProvider = false -- pyright has better placement
    -- client.server_capabilities.documentHighlightProvider = false
    -- client.server_capabilities.documentSymbolProvider = false
    -- client.server_capabilities.workspaceSymbolProvider = false
    -- client.server_capabilities.definitionProvider = nil
    -- client.server_capabilities.declarationProvider = nil
    -- client.server_capabilities.referencesProvider = nil
  end,
}

M.ruff = {
  settings = {
    exclude = python_ignore_paths,
  },
}
return M
