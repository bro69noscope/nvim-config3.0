return {
  "kevinhwang91/nvim-bqf",
  enabled = true,
  ft = "qf",
  opts = {
    preview = {
      auto_preview = false,
      winblend = 0,
      should_preview_cb = function(_, qwinid)
        local title = vim.fn.getqflist({ winid = qwinid, title = 0 }).title
        return title ~= "bqf-nopreview" -- preview everything *except* that tag
      end,
    },
  },
}
