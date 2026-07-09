local M = {}
M.grep_qf_files = function()
  local qflist = vim.fn.getqflist()
  local filetable = {}
  local hashlist = {}
  for _, value in pairs(qflist) do
    local name = vim.api.nvim_buf_get_name(value.bufnr)
    if not hashlist[name] then
      hashlist[name] = true
      table.insert(filetable, name)
    end
  end

  -- Extract just the filenames (tails)
  local filenames = {}
  for _, filepath in ipairs(filetable) do
    table.insert(filenames, vim.fn.fnamemodify(filepath, ":t"))
  end

  local files_str = table.concat(filenames, ", ")
  local prefix = "Grep in " .. #filetable .. " files: "
  local max_files_length = 80 - #prefix - 4 -- 4 for " ..."
  local title = #files_str > max_files_length
      and (prefix .. files_str:sub(1, max_files_length) .. "...")
    or ("Grep in: " .. files_str)

  Snacks.picker.grep({
    dirs = filetable, -- note that the fact we use files directly seems to make globs pattern not
    -- work (either from egrepify or from the grep globs solution we made)
    title = title,
    win = {
      input = {
        keys = require("modules.snacks.picker.keys.setup-all-keys").setup_grep_input_keys(
          filetable,
          title
        ),
      },
    },
  })
end
return M
