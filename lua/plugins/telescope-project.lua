return {
  "nvim-telescope/telescope-project.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  keys = {
    {
      "<leader>.",
      function()
        require("telescope").extensions.project.project({})
      end,
      desc = "Projects (custom)",
    },
  },
}
