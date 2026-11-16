return {
  "folke/lazydev.nvim",
  enabled = true,
  ft = "lua", -- only load on lua files
  opts = {
    library = {
      -- See the configuration section for more details
      -- Load luvit types when the `vim.uv` word is found
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      -- Always load these plugins. lazydev adds a library only when an open buffer requires it
      -- (`require` or `---@module`). Workspace diagnostics check files that are not open, so these
      -- types are otherwise undefined there. Keep this list small: a big library makes lua_ls slow.
      "lazy.nvim", -- LazySpec, LazyPluginSpec
      "snacks.nvim", -- `Snacks` global, snacks.* types
      "oil.nvim",
      "quicker.nvim",
      "csvview.nvim",
      "yazi.nvim",
    },
  },
}
