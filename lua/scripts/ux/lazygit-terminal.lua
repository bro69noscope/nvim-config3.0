local M = {}
local lazygit_term = {
  buf = nil,
  win = nil,
}

local function notify_error(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end

-- Function to create a floating terminal
local function lg_float_term(opts)
  opts = vim.tbl_deep_extend("force", {
    size = { width = 0.96, height = 1.0 },
  }, opts or {})

  local cmd
  if OnWindows then
    cmd = { "cmd.exe", "/C", "lazygit" }

    -- Handle arguments for Windows
    if opts.cmd_args then
      if type(opts.cmd_args) == "string" then
        -- Add the single string as one more argument
        table.insert(cmd, opts.cmd_args)
      elseif type(opts.cmd_args) == "table" then
        -- Add each argument from the table
        for _, arg in ipairs(opts.cmd_args) do
          table.insert(cmd, arg)
        end
      end
    end
  else
    cmd = "lazygit"
    -- Handle arguments for non-Windows
    if opts.cmd_args then
      if type(opts.cmd_args) == "string" then
        cmd = cmd .. " " .. opts.cmd_args
      elseif type(opts.cmd_args) == "table" then
        cmd = cmd .. " " .. table.concat(opts.cmd_args, " ")
      end
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local cols = vim.o.columns
  local lines = vim.o.lines
  local height = math.floor(lines * opts.size.height - (OnNeovide and 1.5 or 0))
  local width = math.floor(cols * opts.size.width)

  local float = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor(lines * (1 - opts.size.height) / 2),
    col = math.floor(cols * (1 - opts.size.width) / 2),
    style = "minimal",
    border = "rounded",
  })

  -- Store in our global reference
  lazygit_term.buf = buf
  lazygit_term.win = float
  local backdrop = require("scripts.ui.create-backdrop-window")
  local bd = backdrop.open({ blend = 40 })
  backdrop.link_to_window(float, bd)

  -- Fix Whichkey delay from waiting for bracket keys combinations
  vim.api.nvim_buf_set_keymap(buf, "t", "]", "]", { noremap = true, nowait = true })
  vim.api.nvim_buf_set_keymap(buf, "t", "[", "[", { noremap = true, nowait = true })

  -- Create terminal
  vim.fn.jobstart(cmd, {
    cwd = vim.fn.getcwd(),
    term = true,
    on_exit = function()
      vim.schedule(function()
        -- Check if the window still exists
        if vim.api.nvim_win_is_valid(lazygit_term.win) then
          vim.api.nvim_win_close(lazygit_term.win, true)
        end
        -- Force delete the buffer
        if vim.api.nvim_buf_is_valid(lazygit_term.buf) then
          vim.api.nvim_buf_delete(lazygit_term.buf, { force = true })
        end
        -- Refresh file and directory views
        vim.cmd("checktime")
        if package.loaded["neo-tree"] then
          pcall(function()
            require("neo-tree.sources.manager").refresh()
          end)
        end
        -- Clear our references
        lazygit_term.buf = nil
        lazygit_term.win = nil
      end)
    end,
  })

  vim.cmd("startinsert")
  return { buf = buf, win = float }
end

-- Function to check clipboard with retries
local function get_relative_file_path(retries, delay)
  local relative_filepath
  for _ = 1, retries do
    relative_filepath = vim.fn.getreg("+")
    if relative_filepath ~= "" then
      return relative_filepath
    end
    vim.loop.sleep(delay)
  end
  return nil
end

-- Function to handle editing from Lazygit
function M.lazygit_edit(original_buffer)
  local current_bufnr = vim.fn.bufnr("%")
  local channel_id = vim.fn.getbufvar(current_bufnr, "terminal_job_id")
  if not channel_id then
    notify_error("No terminal job ID found.")
    return
  end
  vim.fn.chansend(channel_id, "\15") -- \15 is <c-o>
  vim.cmd("close")
  vim.cmd("checktime")
  local relative_filepath = get_relative_file_path(5, 50)
  if not relative_filepath then
    notify_error("Clipboard is empty or invalid.")
    return
  end
  local winid = vim.fn.bufwinid(original_buffer)
  if winid == -1 then
    notify_error("Could not find the original window.")
    return
  end
  vim.fn.win_gotoid(winid)
  vim.cmd("e " .. relative_filepath)
end

-- Function to start Lazygit in a floating terminal
function M.start_lazygit(opts)
  local current_buffer = vim.api.nvim_get_current_buf()
  local float_term = lg_float_term(opts)

  -- Keybind to edit the file in the current nvim instance
  vim.api.nvim_buf_set_keymap(
    float_term.buf,
    "t",
    vim.g.maplocalleader .. "e",
    string.format(
      [[<Cmd>lua require('scripts.ux.lazygit-terminal').lazygit_edit(%d)<CR>]],
      current_buffer
    ),
    { noremap = true, silent = true }
  )

  -- Keybind to write a commit using Tinygit
  vim.api.nvim_buf_set_keymap(
    float_term.buf,
    "t",
    vim.g.maplocalleader .. "c",
    [[<C-\><C-n>:lua RunTinygitSmartCommit()<CR>]],
    { noremap = true, silent = true }
  )

  -- Keybind to amend last commit using Tinygit
  vim.api.nvim_buf_set_keymap(
    float_term.buf,
    "t",
    vim.g.maplocalleader .. "a",
    [[<C-\><C-n>:lua RunTinygitAmendOnlyMessage()<CR>]],
    { noremap = true, silent = true }
  )

  return float_term
end

function M.run_tinygit_command(command)
  vim.cmd("Tinygit " .. command)
  -- Set up a timer to check when Tinygit is done
  local check_timer = vim.loop.new_timer()
  if not check_timer then
    notify_error("Failed to create a timer for checking Tinygit completion.")
    return
  end
  check_timer:start(
    80,
    80,
    vim.schedule_wrap(function()
      -- Check if any of the gitcommit windows are still valid
      local gitcommit_windows_exist = false
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "gitcommit" then
          gitcommit_windows_exist = true
          break
        end
      end
      if not gitcommit_windows_exist then
        -- Return focus to the terminal window if it's still valid
        if vim.api.nvim_win_is_valid(lazygit_term.win) then
          vim.api.nvim_set_current_win(lazygit_term.win)
          vim.cmd("startinsert")
        end
        check_timer:stop()
        check_timer:close()
      end
    end)
  )
end

function M.run_tinygit_smartcommit()
  M.run_tinygit_command("smartCommit")
end

function M.run_tinygit_amendonlymessage()
  M.run_tinygit_command("amendOnlyMsg")
end

-- Make specific functions available globally to use from the floating terminal directly
_G.RunTinygitSmartCommit = M.run_tinygit_smartcommit
_G.RunTinygitAmendOnlyMessage = M.run_tinygit_amendonlymessage

return M
