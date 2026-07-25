return {
  "andymass/vim-matchup",
  opts = {
    treesitter = {
      stopline = 500,
    },
  },
  config = function(_, opts)
    require("match-up").setup(opts)
    vim.keymap.del("i", "<C-G>%") -- invasive keymap for imode c-g binds
  end,
}
