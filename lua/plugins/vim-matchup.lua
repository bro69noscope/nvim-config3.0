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

    local function plug(name)
      return function()
        local count = vim.v.count > 0 and vim.v.count or ""
        vim.cmd.normal(vim.keycode(count .. "<plug>(matchup-" .. name .. ")"))
      end
    end

    local next_match, _ = RepeatablePairs.track_pair(plug("%"), plug("g%"))
    local prev_match, _ = RepeatablePairs.track_pair(plug("g%"), plug("%"))
    vim.keymap.set("n", "%", next_match, { desc = "matchup: % (repeatable)" })
    vim.keymap.set("n", "g%", prev_match, { desc = "matchup: g% (repeatable)" })
  end,
}
