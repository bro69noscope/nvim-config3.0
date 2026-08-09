local M = {}

local function reposition_input_buffer()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local filetype = vim.bo[buf].filetype
    if filetype == "DressingInput" then
      local editor_width = vim.o.columns
      local editor_height = vim.o.lines
      local win_config = vim.api.nvim_win_get_config(win)
      local win_width = math.min(70, editor_width - 4)
      local win_height = win_config.height
      local row = math.floor((editor_height - win_height) / 2)
      local col = math.floor((editor_width - win_width) / 2)
      vim.api.nvim_win_set_config(win, {
        relative = "editor",
        row = row,
        col = col,
        width = win_width,
        height = win_height,
        zindex = 1000,
      })
      vim.b[buf].completion = false
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local is_empty = #lines == 0 or (#lines == 1 and lines[1] == "")
      if is_empty then
        vim.cmd("startinsert")
      end
      break
    end
  end
end

---@param picker snacks.Picker
local function get_search_text(picker)
  local ok, filter = pcall(function()
    return picker:filter()
  end)
  if ok and filter then
    local text = (picker.opts and picker.opts.live) and filter.search or filter.pattern
    if text and text ~= "" then
      return text
    end
    if filter.search and filter.search ~= "" then
      return filter.search
    end
    if filter.pattern and filter.pattern ~= "" then
      return filter.pattern
    end
  end
  return ""
end

--- Builds a named action (picker) -> () usable in a source's `actions` table.
---@param dirs? table<string>
---@param title? string
---@param source? string
M.make_action = function(dirs, title, source)
  local resolved_source = source or "grep"
  return function(picker)
    local current_search = get_search_text(picker)
    local last_patterns = vim.g.snacks_multigrep_patterns or ""
    local setup_all_keys = require("modules.snacks.picker.keys.setup-all-keys")

    picker:close()

    vim.ui.input({
      prompt = "File patterns (comma-separated, e.g., *.lua,*.py,src/**,*/dir/*): ",
      default = last_patterns,
    }, function(input)
      if not input then
        local config_wo_glob = { search = current_search }
        if dirs then
          config_wo_glob.dirs = dirs
        end
        if title then
          config_wo_glob.title = title
        end
        config_wo_glob.win = {
          input = { keys = setup_all_keys.setup_grep_input_keys(dirs, title, resolved_source) },
        }
        vim.schedule(function()
          Snacks.picker.pick(resolved_source, config_wo_glob)
        end)
        return
      end

      local patterns = {}
      for pattern in input:gmatch("([^,]+)") do
        table.insert(patterns, vim.trim(pattern))
      end
      vim.g.snacks_multigrep_patterns = table.concat(patterns, ",")

      local config_w_globs = { search = current_search, glob = patterns }
      if dirs then
        config_w_globs.dirs = dirs
      end
      if #patterns > 0 then
        config_w_globs.title = (title or "Grep") .. " (" .. table.concat(patterns, ", ") .. ")"
      else
        config_w_globs.title = title
      end
      config_w_globs.win = {
        input = { keys = setup_all_keys.setup_grep_input_keys(dirs, title, resolved_source) },
      }

      vim.schedule(function()
        Snacks.picker.pick(resolved_source, config_w_globs)
      end)
    end)

    vim.schedule(function()
      if pcall(require, "dressing") then
        reposition_input_buffer()
      end
    end)
  end
end

return M
