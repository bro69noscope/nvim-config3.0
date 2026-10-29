local M = {}

local function del_mark(ch)
  local ok, res
  if ch:match("%u") then
    ok, res = pcall(vim.api.nvim_del_mark, ch)
  elseif ch:match("%l") then
    ok, res = pcall(vim.api.nvim_buf_del_mark, 0, ch)
  else
    return false
  end
  return ok and res
end

M.delete_mark = function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"

  local width = 50
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = 1,
    row = math.floor((vim.o.lines - 1) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Delete marks (! local  & global  # all) ",
    title_pos = "center",
  })

  local function close()
    vim.cmd("stopinsert")
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function confirm()
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    -- close first so marks are deleted in the original buffer
    close()

    local deleted, failed, seen = {}, {}, {}

    local function has(sym)
      return line:find(sym, 1, true) ~= nil
    end

    if has("#") or has("!") then
      vim.cmd("delmarks!")
      table.insert(deleted, "all local")
    end
    if has("#") or has("&") then
      vim.cmd("delmarks A-Z")
      table.insert(deleted, "all global")
    end

    for ch in line:gmatch("%S") do
      if not ("!&#"):find(ch, 1, true) and not seen[ch] then
        seen[ch] = true
        if del_mark(ch) then
          table.insert(deleted, ch)
        else
          table.insert(failed, ch)
        end
      end
    end

    if #deleted == 0 and #failed == 0 then
      print("Delete mark: nothing entered")
      return
    end
    if #deleted > 0 then
      print("Deleted marks: " .. table.concat(deleted, " "))
    end
    if #failed > 0 then
      vim.notify(
        "Could not delete: " .. table.concat(failed, " "),
        vim.log.levels.WARN,
        { title = "delete-mark" }
      )
    end
    vim.cmd("redraw!")
  end

  local function cancel()
    close()
    print("Delete mark: cancelled")
  end

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set({ "i", "n" }, "<CR>", confirm, opts)
  vim.keymap.set({ "i", "n" }, "<Esc>", cancel, opts)
  vim.keymap.set({ "i", "n" }, "<C-c>", cancel, opts)

  -- cancel if focus leaves the float
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })

  vim.cmd("startinsert")
end

return M
