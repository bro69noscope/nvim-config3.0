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
    { "<leader>Q", "<cmd>Grapple toggle_scopes<cr>", desc = "Grapple toggle scopes" },
    { "g1", "<cmd>Grapple select index=1<cr>", desc = "Grapple select 1" },
    { "g2", "<cmd>Grapple select index=2<cr>", desc = "Grapple select 2" },
    { "g3", "<cmd>Grapple select index=3<cr>", desc = "Grapple select 3" },
    { "g4", "<cmd>Grapple select index=4<cr>", desc = "Grapple select 4" },
    { "g5", "<cmd>Grapple select index=5<cr>", desc = "Grapple select 5" },
    { "g6", "<cmd>Grapple select index=6<cr>", desc = "Grapple select 6" },
    { "g7", "<cmd>Grapple select index=7<cr>", desc = "Grapple select 7" },
    { "g8", "<cmd>Grapple select index=8<cr>", desc = "Grapple select 8" },
    { "g9", "<cmd>Grapple select index=9<cr>", desc = "Grapple select 9" },
    { "g0", "<cmd>Grapple select index=10<cr>", desc = "Grapple select 10" },
    -- idk about those, might use the key for smth else
    { "<Right>", "<cmd>Grapple cycle forward<cr>", desc = "Grapple cycle forward" },
    { "<Left>", "<cmd>Grapple cycle backward<cr>", desc = "Grapple cycle backward" },
  },
}
