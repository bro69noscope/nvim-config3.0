local M = {}

---Find .log files and files in log/ or logs/ directories, gitignored included.
M.open = function()
  Snacks.picker.files({
    title = "Log files",
    ignored = true,
    transform = function(item)
      local f = item.file:gsub("\\", "/"):lower()
      f = "/" .. f
      return f:match("%.log$") ~= nil
        or f:find("/logs/", 1, true) ~= nil
        or f:find("/log/", 1, true) ~= nil
    end,
  })
end

return M
