return {
  "simeji/winresizer",
  enabled = true,
  config = function()
    vim.g.winresizer_horiz_resize = 1
    vim.g.winresizer_vert_resize = 1
    vim.g.winresizer_start_key = "<F24>" -- doesn't work, still starts with default C-e, need to change src code or override bind
  end,
  keys = {
    {
      "<leader>wR",
      "<cmd>WinResizerStartResize<CR>",
      mode = "n",
      silent = true,
      desc = "Start window resize mode",
    },
  },
}
