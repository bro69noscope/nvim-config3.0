return {
  "nvim-telescope/telescope-project.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  -- NOTE: "config is in lua/plugins/telescope.lua"
  keys = {
    {
      PickProjectBind,
      function()
        require("telescope").extensions.project.project({})
      end,
      desc = "Pick Projects",
    },
  },
}
