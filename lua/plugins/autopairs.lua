return {
  "windwp/nvim-autopairs",
  enabled = false,
  event = "InsertEnter",
  config = function()
    local npairs = require("nvim-autopairs")
    npairs.setup({
      check_ts = true,
      fast_wrap = {},
    })

    npairs.get_rules("`")[1].not_filetypes = { "ps1", "psm1" }
  end,
}
