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
    InterpreterPath = "C:/Users/ville/scoop/shims/autohotkey.exe",
    FormatOptions = {
      -- preserve_newlines = true,
      wrap_line_length = 88,
    },
  },
}

return M
