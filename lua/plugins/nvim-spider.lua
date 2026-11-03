return {
  "chrisgrieser/nvim-spider",
  opts = {
    skipInsignificantPunctuation = true,
  },
  config = function(_, opts)
    require("spider").setup(opts)
  end,
  keys = {
    { "w", "<cmd>lua require('spider').motion('w')<CR>", mode = { "n", "o", "x" } },
    { "e", "<cmd>lua require('spider').motion('e')<CR>", mode = { "n", "o", "x" } },
    { "b", "<cmd>lua require('spider').motion('b')<CR>", mode = { "n", "o", "x" } },
    { "ge", "<cmd>lua require('spider').motion('ge')<CR>", mode = { "n", "o", "x" } },
    -- alt+w/e/b: standard vim motions
    { "<M-w>", "w", mode = { "n", "o", "x" }, remap = false },
    { "<M-e>", "e", mode = { "n", "o", "x" }, remap = false },
    { "<M-b>", "b", mode = { "n", "o", "x" }, remap = false },
  },
}
