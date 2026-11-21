local M = {}

---Marks with only user marks a-z / A-Z. Exclude automated marks.
---<m-d> deletes the selected marks.
M.open = function()
  local auto = {}
  for _, m in pairs(_G.Automated_marks) do
    auto[m.key] = true
  end

  Snacks.picker.marks({
    transform = function(item)
      local m = item.label
      return m ~= nil and m:match("^%a$") ~= nil and not auto[m]
    end,

    actions = {
      delete_mark = function(picker)
        local del_mark = require("scripts.ux.delete-mark").del_mark
        for _, item in ipairs(picker:selected({ fallback = true })) do
          -- local marks belong to the buffer the picker was opened from
          del_mark(item.label, item.buf or picker.input.filter.current_buf)
        end
        picker.list:set_selected()
        picker:find()
      end,
    },

    win = {
      input = { keys = { ["<m-d>"] = { "delete_mark", mode = { "n", "i" } } } },
      list = { keys = { ["<m-d>"] = "delete_mark" } },
    },
  })
end

return M
