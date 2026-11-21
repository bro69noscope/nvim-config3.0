local M = {}

---Git branches with the "branch:" prefix in the input, for easy checkout.
M.open = function()
  Snacks.picker.git_branches({
    on_show = function(picker)
      picker.input:set("branch:")
    end,
  })
end

return M
