return {
  "chrisgrieser/nvim-tinygit",
  enabled = true,
  dependencies = { "nvim-telescope/telescope.nvim" },
  cmd = { "Tinygit" },
  keys = {
    {
      "<leader>gi",
      "<cmd>Tinygit interactiveStaging<cr>",
      desc = "Interactive staging",
    },
    {
      "<leader>gc",
      "<cmd>Tinygit smartCommit<cr>",
      desc = "Smart commit",
    },
    {
      "<leader>gP",
      "<cmd>Tinygit push<cr>",
      desc = "Push",
    },
    {
      "<leader>g<c-p>",
      function()
        require("tinygit").push({ forceWithLease = true })
      end,
      desc = "Push (force with lease)",
    },
    {
      "<leader>ga",
      "<cmd>Tinygit amendOnlyMsg<cr>",
      desc = "Amend last commit message",
    },
    {
      "<leader>gA",
      "<cmd>Tinygit amendNoEdit<cr>",
      desc = "Amend last commit noEdit",
    },
    {
      "<leader>g/",
      "<cmd>Tinygit fileHistory<cr>",
      desc = "Grep history",
    },
    {
      "<leader>g<c-u>",
      "<cmd>Tinygit undoLastCommitOrAmend<cr>",
      desc = "Undo last commit or amend",
    },
    {
      "<leader>gF",
      "<cmd>Tinygit fixupCommit<cr>",
      desc = "Fixup commit",
    },
    {
      "<leader>gz",
      "<cmd>Tinygit stashPush<cr>",
      desc = "Stash changes",
    },
    {
      "<leader>gZ",
      "<cmd>Tinygit stashPop<cr>",
      desc = "Pop last stash",
    },
  },
}
