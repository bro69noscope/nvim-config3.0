return {
  "romus204/tree-sitter-manager.nvim",
  dependencies = {}, -- tree-sitter CLI must be installed system-wide
  config = function()
    require("tree-sitter-manager").setup({
      languages = {
        autohotkey = {
          install_info = {
            url = "https://github.com/holy-tao/tree-sitter-autohotkey",
            files = { "src/parser.c" },
            branch = "main",
          },
        },
      },
    })

    -- Disable ahk tree-sitter highlighting
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "autohotkey",
      callback = function()
        vim.schedule(function()
          vim.treesitter.stop()
        end)
      end,
    })
  end,
}
