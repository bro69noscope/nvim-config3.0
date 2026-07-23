vim.api.nvim_set_hl(0, "GrappleActive", { fg = "#ff6186", bold = true })
return {
  "cbochs/grapple.nvim",
  enabled = true,
  opts = {
    scope = "git", -- also try out "git_branch"
    statusline = {
      active = "%%#GrappleActive#[%s]%%#StatusLine#",
      inactive = "%s",
      icon = "󰛢",
      include_icon = true,
    },
  },
  event = { "BufReadPost", "BufNewFile" },
  cmd = "Grapple",
  keys = {
    { "<leader>A", "<cmd>Grapple toggle<cr>", desc = "Grapple toggle tag" },
    {
      "<leader>G",
      function()
        require("grapple").reset()
        require("grapple").tag()
      end,
      desc = "Grapple wipe tags and add current file",
    },
    { "<leader>H", "<cmd>Grapple toggle_tags<cr>", desc = "Grapple toggle tags" },
    { "<leader>T", "<cmd>Grapple toggle_scopes<cr>", desc = "Grapple toggle scopes" },
    { "<leader>1", "<cmd>Grapple select index=1<cr>", desc = "Grapple select 1" },
    { "<leader>2", "<cmd>Grapple select index=2<cr>", desc = "Grapple select 2" },
    { "<leader>3", "<cmd>Grapple select index=3<cr>", desc = "Grapple select 3" },
    { "<leader>4", "<cmd>Grapple select index=4<cr>", desc = "Grapple select 4" },
    { "<leader>5", "<cmd>Grapple select index=5<cr>", desc = "Grapple select 5" },
    { "<leader>6", "<cmd>Grapple select index=6<cr>", desc = "Grapple select 6" },
    { "<leader>7", "<cmd>Grapple select index=7<cr>", desc = "Grapple select 7" },
    { "<leader>8", "<cmd>Grapple select index=8<cr>", desc = "Grapple select 8" },
    { "<leader>9", "<cmd>Grapple select index=9<cr>", desc = "Grapple select 9" },
    { "<leader>0", "<cmd>Grapple select index=10<cr>", desc = "Grapple select 10" },
    -- idk about those, might use the key for smth else
    { "gj", "<cmd>Grapple cycle forward<cr>", desc = "Grapple cycle forward" },
    { "gk", "<cmd>Grapple cycle backward<cr>", desc = "Grapple cycle backward" },
  },
}
