local M = {}

local close_active

local TITLE = " press p to toggle smart/full "

-- Directory names that the smart path always shows as their abbreviation.
local SIGNATURE_DIRS = {
  ["next-level-live-streaming"] = "nlls",
}

-- Shorten all directories to one char, except the root part and the last 3 parts.
-- Signature directories always show as their abbreviation.
local function smart_path(path)
  local full = vim.split(path, "/", { plain = true })
  local short = vim.split(vim.fn.pathshorten(path), "/", { plain = true })

  for i = math.max(2, #full - 2), #full do
    short[i] = full[i]
  end
  short[1] = full[1]

  for i = 1, #full - 1 do
    short[i] = SIGNATURE_DIRS[full[i]] or short[i]
  end

  return table.concat(short, "/")
end

local function float_config(text)
  local max_width = math.floor(vim.o.columns * 0.7)
  local width = math.min(math.max(#text, #TITLE) + 2, max_width)
  local height = math.max(1, math.ceil(#text / width))

  return {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2) - 1,
    width = width,
    height = height,
  }
end

local function show_float(full_text)
  if close_active then
    close_active()
  end

  local texts = { smart = smart_path(full_text), full = full_text }
  local mode = "smart"

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { texts[mode] })

  local config = float_config(texts[mode])
  config.style = "minimal"
  config.border = "rounded"
  config.title = TITLE
  config.title_pos = "center"
  local win = vim.api.nvim_open_win(buf, false, config)

  vim.wo[win].wrap = true

  local function toggle()
    mode = mode == "smart" and "full" or "smart"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { texts[mode] })
    vim.api.nvim_win_set_config(win, float_config(texts[mode]))
  end

  -- Keep the previous buffer-local "p" map to restore it on close.
  local src_buf = vim.api.nvim_get_current_buf()
  local prev_map = vim.fn.maparg("p", "n", false, true)
  vim.keymap.set("n", "p", toggle, { buffer = src_buf, nowait = true })

  local backdrop = require("scripts.ui.create-backdrop-window")
  local backdrop_handle = backdrop.open({ blend = 60 })

  local saved_guicursor = vim.o.guicursor
  vim.api.nvim_set_hl(0, "HiddenCursor", { blend = 100, nocombine = true })
  vim.o.guicursor = "a:HiddenCursor"

  local autocmd_id
  local function close()
    close_active = nil
    pcall(vim.api.nvim_del_autocmd, autocmd_id)
    pcall(vim.keymap.del, "n", "p", { buffer = src_buf })
    if prev_map.buffer == 1 then
      vim.api.nvim_buf_call(src_buf, function()
        vim.fn.mapset("n", false, prev_map)
      end)
    end
    vim.o.guicursor = saved_guicursor
    backdrop.close(backdrop_handle)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  close_active = close

  autocmd_id = vim.api.nvim_create_autocmd({ "CursorMoved", "BufLeave", "InsertEnter" }, {
    once = true,
    callback = close,
  })
end

-- Replace the home directory with "~" and use "/" as separator.
local function home_path(path)
  return (vim.fn.fnamemodify(path, ":~"):gsub("\\", "/"))
end

local function buffer_path()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return "[No Name]"
  end
  return home_path(path)
end

M.show_fullpath_cwd = function()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return show_float("[No Name]")
  end

  path = path:gsub("\\", "/")
  local cwd = vim.fn.getcwd():gsub("\\", "/")
  if path:sub(1, #cwd + 1) == cwd .. "/" then
    return show_float("~" .. path:sub(#cwd + 1))
  end

  show_float(home_path(path))
end

M.show_cwd = function()
  show_float(home_path(vim.fn.getcwd()))
end

M.show_fullpath = function()
  show_float(buffer_path())
end

return M
