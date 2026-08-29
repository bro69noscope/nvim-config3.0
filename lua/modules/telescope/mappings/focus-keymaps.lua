local M = {}

local focus_window

local function setup_focus_keymaps(prompt_bufnr, bufnr, prompt_win)
  vim.keymap.set("n", "i", function()
    vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", prompt_win))
    vim.cmd("startinsert")
  end, { buffer = bufnr })

  vim.keymap.set("n", "q", function()
    require("telescope.actions").close(prompt_bufnr)
  end, { buffer = bufnr })

  vim.keymap.set("n", "<C-l>", function()
    focus_window(prompt_bufnr, "preview")
  end, { buffer = bufnr })

  vim.keymap.set("n", "<C-h>", function()
    focus_window(prompt_bufnr, "results")
  end, { buffer = bufnr })

  vim.keymap.set("n", "<C-j>", "<nop>", { buffer = bufnr })
  vim.keymap.set("n", "<C-k>", "<nop>", { buffer = bufnr })
end

focus_window = function(prompt_bufnr, window_type)
  local action_state = require("telescope.actions.state")
  local picker = action_state.get_current_picker(prompt_bufnr)
  local prompt_win = picker.prompt_win
  local target_win, target_bufnr

  if window_type == "preview" then
    local previewer = picker.previewer
    target_bufnr = previewer.state.bufnr or previewer.state.termopen_bufnr
    target_win = previewer.state.winid or vim.fn.win_findbuf(target_bufnr)[1]
  elseif window_type == "results" then
    target_win = picker.results_win
    target_bufnr = vim.api.nvim_win_get_buf(target_win)
  end

  setup_focus_keymaps(prompt_bufnr, target_bufnr, prompt_win)
  vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", target_win))
end

M.focus_preview = function(prompt_bufnr)
  focus_window(prompt_bufnr, "preview")
end

M.focus_results = function(prompt_bufnr)
  focus_window(prompt_bufnr, "results")
end

return M
