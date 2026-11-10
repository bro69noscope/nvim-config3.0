return {
  -- maintained fork of ThePrimeagen's plugin (the original crashes on Windows paths)
  "polarmutex/git-worktree.nvim",
  version = "^2",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  -- NOTE: the telescope extension ("git_worktree") is loaded in lua/plugins/telescope.lua
  -- No setup() needed; options live in vim.g.git_worktree (see :help git-worktree)
  init = function()
    vim.g.git_worktree = {
      change_directory_command = "cd",
      update_on_change = true,
      update_on_change_command = "e .",
      clearjumps_on_change = true,
      confirm_telescope_deletions = true,
      autopush = false,
    }
  end,
  config = function()
    -- no builtin hooks are registered by default: reopen the current file after a switch
    local hooks = require("git-worktree.hooks")
    hooks.register(hooks.type.SWITCH, hooks.builtins.update_current_buffer_on_switch)
  end,
  -- picker keys intentionally not set yet: the README does not name the telescope functions.
  -- After installing, run :Telescope git_worktree and read the installed source, then bind.
}
