-- pieced with: windows\autohotkey\utils-script\nvim-scratch\scratch.ahk

local scratch_dir = vim.fn.expand("$TEMP"):gsub("\\", "/") .. "/nvim-scratch"
local scratch_pattern = scratch_dir .. "/scratch_*"

vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = scratch_pattern,
  callback = function(_)
    local clip = vim.fn.getreg("+")
    if clip ~= "" then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(clip, "\n"))
    end
  end,
})
