local M = {}

local direct_launch = function(picker_fn, config)
  picker_fn(config)
end

local grep_filename_with = function(modifier)
  return function(picker, item, opts)
    if not item or not item.file then
      return
    end

    local filename = vim.fn.fnamemodify(item.file, modifier)
    local launch = opts and opts.launch or direct_launch

    launch(Snacks.picker.grep_word, {
      title = "Grep for: " .. filename,
      search = filename,
      cwd = picker:cwd(),
      show_empty = true,
    })
  end
end

M.grep_for_filename = grep_filename_with(":t:r")
M.grep_for_filename_with_ext = grep_filename_with(":t")

return M
