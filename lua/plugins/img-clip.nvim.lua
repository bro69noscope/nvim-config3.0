return {
  "HakonHarnes/img-clip.nvim",
  ft = "markdown",
  opts = {
    default = {
      dir_path = "attachments",
      use_absolute_path = false,
      relative_to_current_file = false,
    },
    filetypes = {
      markdown = {
        url_encode_path = true,
        template = "![$CURSOR]($FILE_PATH)",
      },
    },
  },
  keys = { { "<c-p>", "<cmd>PasteImage<cr>", desc = "Paste image" } },
}
