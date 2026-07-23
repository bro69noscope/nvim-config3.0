local M = {}

M.trouble_toggle = Snacks.toggle.new({
  name = "Trouble",
  notify = false,
  get = function()
    return require("trouble").is_open()
  end,
  set = function(enabled)
    if enabled then
      require("trouble").open("diagnostics")
    else
      require("trouble").close()
    end
  end,
})

return M
