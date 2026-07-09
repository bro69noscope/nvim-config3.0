local M = {}

function M.Delete_shada_temp_files()
  -- Use wildcard expansion properly
  local files =
    vim.fn.glob("C:\\Users\\ville\\AppData\\Local\\nvim-data\\shada\\main.shada.tmp*", false, true)

  local deleted = false
  for _, file in ipairs(files) do
    if vim.fn.delete(file) == 0 then
      deleted = true
    end
  end

  if deleted then
    print("Deleted shada temp files")
  else
    print("No shada temp files found or unable to delete")
  end
end

return M
