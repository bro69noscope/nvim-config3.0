return {
  "andymass/vim-matchup",
  enabled = true,
  init = function()
    vim.g.matchup_matchparen_deferred = 1 -- helps reduce lag a lot.
    vim.g.matchup_matchparen_deferred_show_delay = 50 -- ms, default 50
    vim.g.matchup_matchparen_deferred_hide_delay = 700 -- ms, default 700
  end,
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
