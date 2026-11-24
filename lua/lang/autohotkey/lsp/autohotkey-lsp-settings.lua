local M = {}

M.ahk2 = {
  cmd = {
    "node",
    vim.fn.expand("~/myfiles/programs/vscode-autohotkey2-lsp/server/dist/server.js"),
    "--stdio",
  },

  filetypes = { "ahk", "autohotkey", "ah2" },
  single_file_support = true,
  flags = {
    debounce_text_changes = 500,
  },

  init_options = {
    locale = "en-us",
    -- Keep in mind InterpreterPath gets required in the config to find ahk2.exe
    InterpreterPath = "C:/Program Files/AutoHotkey/v2/AutoHotkey64.exe",
    FormatOptions = {
      -- preserve_newlines = true,
      wrap_line_length = 88,
    },
  },
}

return M
