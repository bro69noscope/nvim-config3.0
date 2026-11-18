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
  config = function(_, opts)
    require("lazydev").setup(opts)

    local Util = require("lazydev.util")
    local Workspace = require("lazydev.workspace")
    local add = Workspace.add
    local config = Util.norm(vim.uv.fs_realpath(vim.fn.stdpath("config")))

    -- true when root is a linked worktree of the config repo: its .git file points into
    -- <config>/.git/worktrees/
    local function is_config_worktree(root)
      local f = io.open(root .. "/.git")
      local line = f and f:read("*l")
      if f then
        f:close()
      end
      local gitdir = line and line:match("^gitdir: (.+)$")
      return gitdir ~= nil and vim.startswith(Util.norm(gitdir), config .. "/.git/worktrees/")
    end

    -- a worktree of this config has its own copy of the config modules: do not also add the
    -- main checkout (stdpath("config")) as a library, or each module is defined twice
    function Workspace:add(path)
      local real = type(path) == "string" and vim.uv.fs_realpath(path)
      real = real and Util.norm(real)
      local in_config = real and (real == config or vim.startswith(real, config .. "/"))

      if in_config and not Workspace.is_special(self.root) and is_config_worktree(self.root) then
        return
      end
      return add(self, path)
    end
  end,
}
