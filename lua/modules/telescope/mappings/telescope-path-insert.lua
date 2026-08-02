local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local telescope = require("telescope")

local function convert_path(path)
  return path:gsub("\\", "/")
end

local function get_relative_path(path)
  local relative = vim.fn.fnamemodify(path, ":.")
  return convert_path(relative)
end

local function insert_path(prompt_bufnr, use_relative, as_python_import)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    print("No selection")
    return
  end
  local path = selection.path
  if path == nil then
    print("No path")
    return
  end
  if use_relative then
    path = get_relative_path(path)
  else
    path = convert_path(path)
  end

  if as_python_import then
    path = path:gsub("/__init__%.py$", "")
    path = path:gsub("%.py$", "")
    path = path:gsub("/", ".")
    path = path:gsub("^%.", "")
    path = "from " .. path .. " import "
  end

  actions.close(prompt_bufnr)

  -- Insert the path
  vim.api.nvim_put({ path }, "", false, true)
end

local insert_absolute_path = function(prompt_bufnr)
  insert_path(prompt_bufnr, false, false)
end

local insert_relative_path = function(prompt_bufnr)
  insert_path(prompt_bufnr, true, false)
end

local insert_python_import_path = function(prompt_bufnr)
  insert_path(prompt_bufnr, true, true)
end

telescope.setup({
  defaults = {
    mappings = {
      n = {
        ["="] = insert_absolute_path,
        ["-"] = insert_relative_path,
        -- ["<BS>"] = insert_python_import_path, NOTE: idk about keeping this
      },
    },
  },
})

vim.keymap.set("i", "<C-t>", function()
  require("telescope.builtin").find_files()
end, { noremap = true, silent = true, desc = "Telescope find files" })
