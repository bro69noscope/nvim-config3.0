return {
  "nvim-telescope/telescope-project.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  keys = {
    {
      "<leader>p",
      function()
        require("telescope").extensions.project.project({})
      end,
      desc = "Pick Projects",
    },
  },
}
