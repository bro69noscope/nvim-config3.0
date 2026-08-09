local map = require("scripts.ui.whichkey-map").map

-- lateral movement with H and L except in neo-tree
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "*",
--   callback = function()
--     if vim.bo.buftype ~= "neo-tree" then
--       map("n", "<m-h>", "15zh", { desc = "Move cursor 15 spaces to the left" })
--       map("n", "<m-l>", "15zl", { desc = "Move cursor 15 spaces to the right" })
--     end
--   end,
-- })

-- lateral movement with m-h and m-l (meta key)
map("n", "<m-h>", "15zh", { desc = "Move cursor 15 spaces to the left" })
map("n", "<m-l>", "15zl", { desc = "Move cursor 15 spaces to the right" })

-- better indenting
map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Exit terminal mode
map("t", "<C-q>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- leader qq to quit all
map({ "n", "v" }, "<leader>qq", ":<C-u>qa<CR>", { desc = "Quit all", silent = true })
map({ "n", "v" }, "<leader>qf", ":<C-u>cq<CR>", { desc = "Quit and fail", silent = true })
map({ "n", "v" }, "<leader>qt", "<cmd>TabcloseBetter<cr>", { desc = "Close tab", silent = true })
map({ "n", "v" }, "<leader>qo", "<cmd>tabonly<cr>", { desc = "Close other tabs", silent = true })

-- save with C-S
map("n", "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file", silent = true })

-- Center after most code navigation commands
map("n", "G", "Gzz", { desc = "Go to end and center" })
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
map("n", "<C-O>", "<C-O>zz", { desc = "Jump back and center" })
map("n", "<C-I>", "<C-I>zz", { desc = "Jump forward and center" })
map("n", "{", "{zz", { desc = "Previous paragraph and center" })
map("n", "}", "}zz", { desc = "Next paragraph and center" })
map("n", "n", "nzz", { desc = "Next search and center" })
map("n", "N", "Nzz", { desc = "Previous search and center" })
map("n", "*", "*zz", { desc = "Search word under cursor and center" })
map("n", "#", "#zz", { desc = "Search word under cursor backward and center" })
-- map("n", "%", "%zz", { desc = "Match bracket and center" })

-- Open Lazy floating window
map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy", icon = "󰒲" })

-- Rebind macro key cause mistakes are made too often lol
map("n", "q", "", { desc = "Disabled (use Q for macros)" })
map("n", "Q", "q", { desc = "Record macro" })

-- Delete whole word with ctrl+backspace (interpreted as <C-h> in terminal)
map("i", "<C-h>", "<C-w>", { desc = "Delete word backward" })

-- Close (non-focused) floating windows and disable search hl with ESC
map("n", "<esc>", function()
  local current_win = vim.api.nvim_get_current_win()
  local current_config = vim.api.nvim_win_get_config(current_win)
  if current_config.relative ~= "" then
    vim.cmd("noh")
    return
  end
  local clear = require("scripts.ui.close-floating-windows")
  clear.clear_stuff()
end, { desc = "Close floating windows/disable search highlight" })

-- Set focus on solo windows + main filetree explorer
map("n", "<leader>wo", function()
  require("scripts.ui.close-other-windows").solo_window_with_filetree()
end, { desc = "Close others (and opens File Explorer)", icon = "" })

-- force C-n and C-p to navigate cmd/search history (fixes cmp issues)
map("c", "<C-n>", "<C-Down>", { desc = "Navigate cmd history (next)" })
map("c", "<C-p>", "<C-Up>", { desc = "Navigate cmd history (previous)" })

-- Search within visual selection
map("x", "<leader>/", "<Esc>/\\%V", { desc = "Search within selection" })

-- Open file in PyCharm at current line
map("n", "<leader>oP", function()
  local path = vim.api.nvim_buf_get_name(0)
  local row = unpack(vim.api.nvim_win_get_cursor(0))
  local command = ("pycharm --line " .. row .. " " .. path .. "")
  print(command)
  os.execute(command)
end, { desc = "Open line in PyCharm", icon = { icon = "", color = "yellow" } })

-- Focus windows
local focus_win = require("scripts.ux.focus-windows")

map("n", "<leader>wi", function()
  focus_win.largest()
end, { desc = "Focus largest window" })

map("n", "<leader>wc", function()
  focus_win.quickfix()
end, { desc = "Focus quickfix window" })

map("n", "<leader>wx", function()
  focus_win.snacks_explorer()
end, { desc = "Focus snacks explorer window" })

-- Quickfix navigation
map("n", "<Up>", function()
  local ok, err = pcall(vim.cmd.cprev)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
  vim.cmd("normal! zz")
end, { desc = "Previous Quickfix Item" })

map("n", "<Down>", function()
  local ok, err = pcall(vim.cmd.cnext)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
  vim.cmd("normal! zz")
end, { desc = "Next Quickfix Item" })

-- Format with custom width
local function format_with_width()
  local width = vim.fn.input("Format to width: ")
  if width ~= "" and tonumber(width) and tonumber(width) > 0 then
    local old_tw = vim.o.textwidth
    vim.o.textwidth = tonumber(width)
    vim.cmd("normal! gw")
    vim.o.textwidth = old_tw
  end
end
map("v", "gW", format_with_width, { desc = "Format with custom width" })

-- Clipboard operations
map({ "n", "v" }, "<C-c>", function()
  vim.fn.feedkeys('"+y')
end, { desc = "Yank to system clipboard" })

map("n", "<leader>ya", function()
  require("scripts.utils.clipboard-functions").copy_file_to_system_register()
end, { desc = "Copy file content to system clipboard" })

map("n", "<leader>yA", function()
  require("scripts.utils.clipboard-functions").append_file_to_system_register()
end, { desc = "Append file content to system clipboard" })

map("n", "<leader>yc", function()
  require("scripts.utils.clipboard-functions").copy_code_to_system_register()
end, { desc = "Copy file content with header to system clipboard" })

map("n", "<leader>yC", function()
  require("scripts.utils.clipboard-functions").append_code_to_system_register()
end, { desc = "Append file content with header to system clipboard" })

map("n", "<leader>yq", function()
  require("scripts.utils.clipboard-functions").copy_qf_code_to_register()
end, { desc = "Copy quickfix code to system clipboard" })

map("n", "<leader>yQ", function()
  require("scripts.utils.clipboard-functions").append_qf_code_to_register()
end, { desc = "Append quickfix code to system clipboard" })

map("n", "<leader>+", function()
  require("scripts.utils.clipboard-functions").append_unnamed_reg_to_system_reg()
end, { desc = "Append unnamed reg to clipboard", icon = "📋" })

map("n", "<leader>=", function()
  vim.fn.setreg("+", vim.fn.getreg('"'))
end, { desc = "Copy unnamed reg to clipboard", icon = "📋" })

-- Various uitilities
map("n", "<leader>uf", function()
  require("scripts.ui.transform-windows").make_window_floating()
end, { desc = "Make window floating" })

map("n", "<Leader>uB", function()
  require("scripts.utils.various-utils").capture_current_buffer_info()
end, { desc = "Capture current buffer name" })

map("n", "<leader>ub", function()
  local bufinfo =
    require("scripts.utils.various-utils").capture_current_buffer_info({ silent = true })
  local bufname, raw_bufname = bufinfo.bufname, bufinfo.raw_bufname
  vim.notify("path: " .. bufname .. "\n" .. "raw: " .. raw_bufname, vim.log.levels.INFO)
  vim.fn.setreg("+", bufname)
end, { desc = "Yank current buffer name to clipboard" })

-- Path quick conversion
map("n", "<leader>\\", function()
  require("scripts.edit.edit-path-separators").convert_path_separators()
end, { desc = "Convert path separators", icon = "🔀" })

-- Invert (flip flop) comments with gC, in normal and visual mode
map(
  { "n", "x" },
  "gC",
  "<cmd>set operatorfunc=v:lua.__flip_flop_comment<cr>g@",
  { silent = true, desc = "Invert comments" }
)

-- Swap true/false keywords
map("n", "<leader>S", function()
  require("scripts.edit.swap-true-false-keywords").swap_keywords()
end, { desc = "Swap true/false keywords", icon = "" })

-- Manipulate windows size
map("n", "<leader>wm", function()
  require("scripts.ui.resize-windows").maximize_window()
end, { desc = "Maximize window size" })

map("n", "<leader>ws", function()
  require("scripts.ui.resize-windows").set_window()
end, { desc = "Set window size" })

map("n", "<leader>wr", function()
  require("scripts.ui.resize-windows").restore_window()
end, { desc = "Restore window size" })

map("n", "<leader>wh", function()
  require("scripts.ui.resize-windows").half_size_window()
end, { desc = "Set window to half size" })

-- Yank buffer's paths to clipboard
map("n", "<leader>yp", function()
  local relative_path = vim.fn.expand("%:p:~:.")
  vim.fn.setreg("+", relative_path)
  vim.notify("Relative path copied to clipboard: " .. relative_path, vim.log.levels.INFO)
end, { desc = "Yank buffer relative path to clipboard" })

map("n", "<leader>yP", function()
  local absolute_path = vim.fn.expand("%:p")
  vim.fn.setreg("+", absolute_path)
  vim.notify("Absolute path copied to clipboard: " .. absolute_path, vim.log.levels.INFO)
end, { desc = "Yank buffer absolute path to clipboard" })

-- Delete marks with gmd
map("n", "gmd", function()
  require("scripts.ux.delete-mark").delete_mark()
end, { desc = "Delete mark(s)", icon = { icon = "❌", color = "red" } })

-- Open Lazygit in a floating terminal
map("n", "<leader>gg", function()
  require("scripts.ux.lazygit-terminal").start_lazygit({ cmd_args = "" })
end, { desc = "Open Lazygit in floating terminal" })

map("n", "<leader>gol", function()
  require("scripts.ux.lazygit-terminal").start_lazygit({ cmd_args = "log" })
end, { desc = "Open Lazygit logs in floating term" })

-- Open multiple buffers (meant to populate diagnostics over multiple files)
map("n", "<leader>xo", function()
  require("scripts.ux.diagnose-multiple-buffers").open_buffers()
end, { desc = "Open buffers from path", icon = "📂" })

-- Remove trailing whitespace
map(
  "n",
  "<leader>u<space>",
  "<cmd>keeppatterns %s/\\s\\+$//e<CR>",
  { desc = "Remove trailing whitespace" }
)

-- dbui test
vim.keymap.set("n", "g]", "gt", { desc = "Next tab" })
vim.keymap.set("n", "g[", "gT", { desc = "Previous tab" })

-- Generate symbol refactor template for symbol under cursor
map("n", "<leader>rs", function()
  local template =
    require("lang.python.grugfar-astgrep.symbol-imports").generate_template_for_symbol()
  if template then
    require("grug-far").open({
      engine = "astgrep-rules",
      prefills = {
        rules = template,
        replacement = "",
      },
    })
  end
end, { desc = "Generate symbol refactor template" })

-- Open custom log file in new tab
map("n", "<leader>ol", function()
  require("config.custom-logging").open_log_file()
end, { desc = "Open custom log file", icon = "📄" })

-- Open new tab
map("n", "<leader>ot", "<cmd>tabnew<cr>", { desc = "new tab" })

-- Open new wezterm tab in current cwd
map("n", "<leader>to", function()
  require("scripts.ux.open-cwd-wezterm").new_cwd_wezterm_tab()
end, { desc = "Open WezTerm tab at cwd" })

-- Try to format lines too long without lsp/formatter
map(
  "n",
  "<leader>rl",
  require("scripts.ux.format-longlines").makeshift_format,
  { desc = "Scuffed Format long lines in file", icon = "🤡" }
)

-- set cwd to parent directory of current file
map("n", "<leader>.", function()
  vim.cmd("cd %:p:h")
end, { desc = "Set cwd to parent directory" })

-- move cwd up one directory level
map("n", "<BS>", function()
  require("scripts.ux.move-cwd-level").move_cwd_up_one_level()
end, { desc = "Move cwd up one level" })

-- move cwd down one directory level
map("n", "<M-BS>", function()
  require("scripts.ux.move-cwd-level").move_cwd_down_one_level()
end, { desc = "Move cwd down one level" })

-- set cwd to project root (git root)
map("n", "<leader>R", function()
  require("scripts.ux.move-cwd-level").set_cwd_to_project_root()
end, { desc = "Set cwd to project root" })

-- move lines up and down
map("n", "<M-K>", ":m .-2<CR>==", { silent = true })
map("n", "<M-J>", ":m .+1<CR>==", { silent = true })

-- add current line to quickfix list
map("n", "<leader>cl", function()
  vim.fn.setqflist({}, "a", {
    items = {
      {
        filename = vim.fn.expand("%"),
        lnum = vim.fn.line("."),
        col = vim.fn.col("."),
        text = vim.fn.getline("."),
      },
    },
  })
end, { desc = "Add current line to quickfix" })

-- serch visual selection in explorer
map("x", "<leader>se", function()
  require("scripts.ux.search-with-explorer").open_selection_in_explorer()
end, { desc = "Open selected path in explorer" })

-- Repeatable movement for misspelled words
local function next_spell()
  vim.cmd("normal! ]s")
end

local function prev_spell()
  vim.cmd("normal! [s")
end

local next_spell_r, prev_spell_r = RepeatablePairs.track_pair(next_spell, prev_spell)

map("n", "]s", next_spell_r, { desc = "Next misspelled word" })
map("n", "[s", prev_spell_r, { desc = "Previous misspelled word" })

-- to undo the LLM alignment non-sense
local function unalign()
  local range = "%"
  if vim.fn.mode() == "v" or vim.fn.mode() == "V" or vim.fn.mode() == "\22" then
    range = "'<,'>"
  end
  vim.cmd(range .. [[s/\S\zs\s\{2,}/ /g]])
end

map({ "n", "x" }, "<leader>ua", unalign, { desc = "Unalign: collapse multi-space to single" })

-- Easier to press last yank from imode
map("i", "<C-r><C-n>", "<C-r>0", { noremap = true, desc = "Insert register 0" })
