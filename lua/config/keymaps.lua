local map = require("scripts.ui.whichkey-map").map

-- important remap to work with glove80 special layout
-- treat {} like [] for mirrored bracket navigation
map({ "n", "x", "o" }, "{", "[", { remap = true })
map({ "n", "x", "o" }, "}", "]", { remap = true })
-- remap () to {} for paragraph navigation
map({ "n", "x", "o" }, "(", "{zz")
map({ "n", "x", "o" }, ")", "}zz")

-- Remove [] bloat
vim.keymap.del("n", "]t")
vim.keymap.del("n", "[t")
vim.keymap.del("n", "]T")
vim.keymap.del("n", "[T")

vim.keymap.del("n", "]q")
vim.keymap.del("n", "[q")
vim.keymap.del("n", "]Q")
vim.keymap.del("n", "[Q")

vim.keymap.del("n", "]l")
vim.keymap.del("n", "[l")
vim.keymap.del("n", "]L")
vim.keymap.del("n", "[L")

vim.keymap.del("n", "]A")
vim.keymap.del("n", "[A")

vim.keymap.del("n", "]<c-l>")
vim.keymap.del("n", "[<c-l>")

vim.keymap.del("n", "[<c-q>")
vim.keymap.del("n", "]<c-q>")

vim.keymap.del("n", "]<c-t>")
vim.keymap.del("n", "[<c-t>")

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
map("n", "<m-h>", "15zh", { desc = "Move cursor 15 spaces left" })
map("n", "<m-l>", "15zl", { desc = "Move cursor 15 spaces right" })

-- better indenting
map("v", "<", "<gv", { desc = "Indent left aNd reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })
map("n", ">", ">>", { desc = "Indent line" })
map("n", "<", "<<", { desc = "Unindent line" })
map("n", "<leader>>", ">", { desc = "Indent line (operator)" })
map("n", "<leader><", "<", { desc = "Unindenk line (operator)" })

-- Exit terminal mode
map("t", "<c-q>", [[<C-\><c-n>]], { desc = "Exit terminal mode" })

-- quit commands
map({ "n", "v" }, "<leader>qq", ":<c-u>qa<CR>", { desc = "Quit all", silent = true })
map({ "n", "v" }, "<leader>qf", ":<c-u>cq<CR>", { desc = "Quit and fail", silent = true })
map({ "n", "v" }, "<leader>qt", "<cmd>TabcloseBetter<cr>", { desc = "Close tab", silent = true })
map({ "n", "v" }, "<leader>qo", "<cmd>tabonly<cr>", { desc = "Close other tabs", silent = true })
map("n", "<leader>q<BS>", function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  vim.fn.setreg("+", table.concat(lines, "\n"))
  vim.cmd("qa!")
end, { desc = "Clip buffer content & quit", icon = "📋", silent = true })

-- save with c-s
map("n", "<c-s>", "<cmd>w<cr><esc>", { desc = "Save file", silent = true })
map("n", SaveAllBind, "<cmd>wa<cr><esc>", { desc = "Save all files", silent = true })
-- noa save
map(
  "n",
  "<leader><c-s>",
  "<cmd>noa w<cr><esc>",
  { desc = "Save file (no autocommands)", silent = true }
)

-- Center after most code navigation commands
map("n", "G", "Gzz", { desc = "Go to end and center" })
map("n", "<c-d>", "<c-d>zz", { desc = "Scroll down and center" })
map("n", "<c-u>", "<c-u>zz", { desc = "Scroll up and center" })
map("n", "<c-o>", "<c-o>zz", { desc = "Jump back and center" })
map("n", "<c-i>", "<c-i>zz", { desc = "Jump forward and center" })
-- map("n", "{", "{zz", { desc = "Previous paragraph and center" })
-- map("n", "}", "}zz", { desc = "Next paragraph and center" })
map("n", "n", "nzz", { desc = "Next search and center" })
map("n", "N", "Nzz", { desc = "Previous search and center" })
map("n", "*", "*zz", { desc = "Search word under cursor" })
map("n", "#", "#zz", { desc = "Search cursor word backward" })
-- map("n", "%", "%zz", { desc = "Match bracket and center" })
map({ "n", "i" }, "<PageUp>", "<Cmd>normal! <c-b>zz<CR>")
map({ "n", "i" }, "<PageDown>", "<Cmd>normal! <c-f>zz<CR>")

-- Open Lazy floating window
map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy", icon = "󰒲" })

-- Rebind macro key cause mistakes are made too often lol
map("n", "q", "", { desc = "Quit things (use " .. MacroBind .. " for macros)" })
map("n", MacroBind, "q", { desc = "Record macro" })

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
end, { desc = "Close floats/disable search hl" })

-- Set focus on solo windows + main filetree explorer
map("n", "<leader>wo", function()
  require("scripts.ui.close-other-windows").solo_window_with_filetree()
end, { desc = "Close others, open explorer", icon = "" })

-- Search within visual selection
map("x", "<leader>/", "<Esc>/\\%V", { desc = "Search within selection" })
-- map("x", "<leader>%", "<Esc>/\\%V", { desc = "Search within selection" }) -- duplicate for enthium layout

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

map("n", "<leader>we", function()
  focus_win.snacks_explorer()
end, { desc = "Focus snacks explorer window" })

map("n", "<leader>wt", function()
  focus_win.terminal()
end, { desc = "Focus terminal window" })

-- Quickfix navigation
local function qf_step(cmd)
  -- dont flood the msg board with llm notes qf content
  local notes = require("scripts.ui.claude-qf-notes.navigate").is_current_list()
  local ok, err = pcall(vim.cmd, (notes and "silent " or "") .. cmd)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
  vim.cmd("normal! zz")
end

map("n", "<Up>", function()
  qf_step("cprev")
end, { desc = "Previous Quickfix Item" })

map("n", "<Down>", function()
  qf_step("cnext")
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
local clip_utils = require("scripts.utils.clipboard-functions")

map({ "n", "v" }, "<c-c>", function()
  vim.fn.feedkeys('"+y')
end, { desc = "Yank to clipboard" })

vim.keymap.set({ "n", "v" }, "<C-Insert>", function()
  vim.fn.feedkeys('"+y')
end, { desc = "Yank to clipboard" })

-- enable omode <m-y><m-y> to yank current line and append to clipboard
map("o", "<m-y>", "_", { desc = "current line (<m-y> doubled)" })

map("n", "<m-y>", function()
  clip_utils.append_yank_to_system_reg_op()
end, { desc = "Yank and append to clipboard" })

map("v", "<m-y>", function()
  clip_utils.append_yank_to_system_reg_visual()
end, { desc = "Append selection to clipboard" })

map("n", "<leader>ya", function()
  clip_utils.copy_file_to_system_register()
end, { desc = "Copy file content to clipboard" })

map("n", "<leader>yA", function()
  clip_utils.append_file_to_system_register()
end, { desc = "Append file content to clip" })

map("n", "<leader>yc", function()
  clip_utils.copy_code_to_system_register()
end, { desc = "Clip code + filename" })

map("n", "<leader>yC", function()
  clip_utils.append_code_to_system_register()
end, { desc = "Append code + fname to clip" })

map("n", "<leader>yq", function()
  clip_utils.copy_qf_code_to_register()
end, { desc = "Copy quickfix code to clip" })

map("n", "<leader>yQ", function()
  clip_utils.append_qf_code_to_register()
end, { desc = "Append qf code + fname to clip" })

map("n", "<leader>yf", function()
  local file_name = vim.fn.expand("%:t:r")
  vim.fn.setreg("+", file_name)
  vim.notify("File name copied to clipboard: " .. file_name, vim.log.levels.INFO)
end, { desc = "Yank current fname to clip", icon = "" })

map("n", "<leader>yF", function()
  local file_name = vim.fn.expand("%:t")
  vim.fn.setreg("+", file_name)
  vim.notify("File path copied to clipboard: " .. file_name, vim.log.levels.INFO)
end, { desc = "Yank fname + ext. to clip", icon = "" })

map("n", "<leader>y.", function()
  local cwd = vim.fn.getcwd()
  vim.fn.setreg("+", cwd)
  vim.notify("CWD copied to clipboard: " .. cwd, vim.log.levels.INFO)
end, { desc = "Yank cwd to clipboard", icon = "📂" })

-- Various uitilities
local various_utils = require("scripts.utils.various-utils")
map("n", "<Leader>ub", function()
  various_utils.capture_current_buffer_info()
end, { desc = "Get current buffer info" })

map("n", "<leader>ut", function()
  various_utils.list_treesitter_installed_parsers()
end, { desc = "List installed TS parsers", icon = "🌲" })

map("n", "<leader>ud", "<cmd>diffthis<CR>", { desc = "diffthis", icon = "󰆊" })
-- Path quick conversion
map({ "n", "x" }, "<leader>\\", function()
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
  require("scripts.ui.resize-windows").half_size_window_horizontal()
end, { desc = "Halve window horizontal size" })

map("n", "<leader>wH", function()
  require("scripts.ui.resize-windows").half_size_window_vertical()
end, { desc = "Halve window vertical size" })

-- Yank buffer's paths to clipboard
map("n", "<leader>yp", function()
  local relative_path = vim.fn.expand("%:p:~:.")
  vim.fn.setreg("+", relative_path)
  vim.notify("Relative path copied to clipboard: " .. relative_path, vim.log.levels.INFO)
end, { desc = "Clip buffer relative path", icon = "" })

map("n", "<leader>yP", function()
  local absolute_path = vim.fn.expand("%:p")
  vim.fn.setreg("+", absolute_path)
  vim.notify("Absolute path copied to clipboard: " .. absolute_path, vim.log.levels.INFO)
end, { desc = "Clip buffer absolute path", icon = "" })

-- Delete marks with gmd
map("n", "gmd", function()
  require("scripts.ux.delete-mark").delete_mark()
end, { desc = "Delete mark(s)", icon = { icon = "❌", color = "red" } })

-- Open Lazygit in a floating terminal
map("n", "<leader>gg", function()
  require("scripts.ux.lazygit-terminal").start_lazygit({ cmd_args = "" })
end, { desc = "Open Lazygit in float term" })

map("n", "<leader>gG", function()
  require("scripts.ux.move-cwd-level").set_cwd_to_project_root({ look_up = false })
  require("scripts.ux.lazygit-terminal").start_lazygit({ cmd_args = "" })
end, { desc = "Open LG in buffer git root" })

map("n", "<leader>gol", function()
  require("scripts.ux.lazygit-terminal").start_lazygit({ cmd_args = "log" })
end, { desc = "Open Lazygit logs (float)" })

-- Git pull current branch
local gitpull = require("scripts.ux.git.gitpull")
gitpull.setup({})
map("n", "<leader>gp", gitpull.pull, { desc = "Git pull current branch" })

-- Git unstage
local gitunstage = require("scripts.ux.git.gitunstage")
map("n", "<leader>gu", gitunstage.unstage_file, { desc = "Git unstage file" })
map("n", "<leader>gU", gitunstage.unstage_all, { desc = "Git unstage all" })
map("n", "<leader>g<m-u>", gitunstage.restore, { desc = "Git undo unstage" })

-- Jump to / live-diff the same file in another worktree (same line, picker if several)
map("n", "<leader>gj", function()
  require("scripts.ux.worktrees.worktree-jump").jump()
end, { desc = "Jump to file in other worktree" })

map("n", "<leader>gJ", function()
  require("scripts.ux.worktrees.worktree-jump").jump({ diff = true })
end, { desc = "Diff file vs other worktree" })

-- Ai worktree custom workflow keymaps:
-- which-key has no pink color preset, so use a custom highlight group. Set it again after a
-- colorscheme change, because the change clears it.
local function set_llm_icon_hl()
  vim.api.nvim_set_hl(0, "LlmWorktreeIcon", { fg = "#f5a3d0" })
end
set_llm_icon_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_llm_icon_hl })
local llm_icon = { icon = "󱚥", hl = "LlmWorktreeIcon" }

-- Pull the LLM worktree's work into main as unstaged changes (real git conflicts)
map("n", "<leader>ip", function()
  require("scripts.ux.worktrees.llm-worktreemerge").pull_from_llm_worktree()
end, { desc = "Pull from LLM worktree", icon = llm_icon })

-- Pull again ignoring the last pull, so changes main undid since come back
map("n", "<leader>iP", function()
  require("scripts.ux.worktrees.llm-worktreemerge").pull_from_llm_worktree({ again = true })
end, { desc = "Re-pull all from LLM worktree", icon = llm_icon })

-- Put current wt back to right before the last pull (files, staging, pulled mark)
map("n", "<leader>iu", function()
  require("scripts.ux.worktrees.llm-worktreemerge").undo_pull()
end, { desc = "Undo last LLM worktree pull", icon = llm_icon })

-- After resolving a pull's conflicts, put those files' staging back to before the pull
map("n", "<leader>ir", function()
  require("scripts.ux.worktrees.llm-worktreemerge").restore_resolved_staging()
end, { desc = "Restore staging after LLM pull", icon = llm_icon })

-- Pull so that only the pulled code is unstaged, to review and tweak it before keeping it
map("n", "<leader>iv", function()
  require("scripts.ux.worktrees.llm-worktreemerge").pull_from_llm_worktree({ review = true })
end, { desc = "Review pull from LLM worktree", icon = llm_icon })

-- Same as <leader>iv, but ignore the last pull, so changes main undid since come back
map("n", "<leader>iV", function()
  require("scripts.ux.worktrees.llm-worktreemerge").pull_from_llm_worktree({
    again = true,
    review = true,
  })
end, { desc = "Re-pull LLM wt for review", icon = llm_icon })

-- Send the reviewed tree back to the LLM worktree, with user tweaks as its HEAD commit, then
-- revert the review pull
map("n", "<leader>ib", function()
  require("scripts.ux.worktrees.llm-worktreemerge").send_review()
end, { desc = "Send review back to LLM wt", icon = llm_icon })

-- Same as <leader>ib, and copy a prompt that tells the LLM to read tweaks
map("n", "<leader>iB", function()
  require("scripts.ux.worktrees.llm-worktreemerge").send_review({ copy_prompt = true })
end, { desc = "Send review + clip LLM prompt", icon = llm_icon })

-- After a review pull: stage only the pulled code (our staging is saved for <leader>ig)
map("n", "<leader>ia", function()
  require("scripts.ux.worktrees.llm-worktreemerge").stage_review()
end, { desc = "Stage only reviewed LLM code", icon = llm_icon })

-- After a review pull: stage the pulled code on top of our staging from before the pull
map("n", "<leader>iA", function()
  require("scripts.ux.worktrees.llm-worktreemerge").stage_review({ with_staged = true })
end, { desc = "Stage reviewed + prior staging", icon = llm_icon })

-- After committing what stage_review staged: put our staging from before the review pull back on
map("n", "<leader>ig", function()
  require("scripts.ux.worktrees.llm-worktreemerge").restore_staging_after_review()
end, { desc = "Add pre-review staging", icon = llm_icon })

-- Same as <leader>ig, but unstage everything first: only the staging from before the pull is staged
map("n", "<leader>iG", function()
  require("scripts.ux.worktrees.llm-worktreemerge").restore_staging_after_review({
    only_saved = true,
  })
end, { desc = "Restore pre-review staging", icon = llm_icon })

-- After a review pull: keep the pulled code unstaged, put our staging from before the pull back
map("n", "<leader>ic", function()
  require("scripts.ux.worktrees.llm-worktreemerge").confirm_review()
end, { desc = "Accept reviewed code, unstaged", icon = llm_icon })

-- After committing during a pull: move the pull onto the new HEAD, so <leader>iu/ib/ia/ic work
map("n", "<leader>im", function()
  require("scripts.ux.worktrees.llm-worktreemerge").catch_up_pull()
end, { desc = "Move LLM pull onto HEAD", icon = llm_icon })

-- Overwrite the LLM worktree with main's state (main wins; its edits are backed up)
map("n", "<leader>is", function()
  require("scripts.ux.worktrees.llm-worktreemerge").overwrite_llm_worktree()
end, { desc = "Send to LLM worktree", icon = llm_icon })

-- Stage the hunks of our unstaged changes that the LLM worktree doesn't have
map("n", "<leader>ih", function()
  require("scripts.ux.worktrees.llm-worktreemerge").stage_unshared_hunks()
end, { desc = "Stage non-LLM-worktree hunks", icon = llm_icon })

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
vim.keymap.set("n", "<end>", "gt", { desc = "Next tab" })
vim.keymap.set("n", "<home>", "gT", { desc = "Previous tab" })

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
end, { desc = "Gen symbol refactor template" })

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

map("n", "<leader>tO", function()
  require("scripts.ux.open-cwd-wezterm").new_cwd_this_file_wezterm_tab()
end, { desc = "Open WezTerm tab at file's cwd" })

-- Try to format lines too long without lsp/formatter
map(
  "n",
  "<leader>rl",
  require("scripts.ux.format-longlines").makeshift_format,
  { desc = "Scuffed format long lines", icon = "🤡" }
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
map("n", "<leader>`", function()
  require("scripts.ux.move-cwd-level").set_cwd_to_project_root()
end, { desc = "Set cwd to project root" })

-- move lines up and down
map("n", SwapLineUpBind, ":m .-2<CR>==", { silent = true })
map("n", SwapLineDownBind, ":m .+1<CR>==", { silent = true })

-- No-op these outside of diffview
map("n", NextDiffConflictBind, "<Nop>")
map("n", PrevDiffConflictBind, "<Nop>")

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

-- AI qf notes keymaps
map("n", "<leader>in", function()
  require("scripts.ui.claude-qf-notes.navigate").open({ copen = false })
end, { desc = "Open ai notes (no qf win)" })

map("n", "<leader>iN", function()
  require("scripts.ui.claude-qf-notes.navigate").open()
end, { desc = "Open ai notes with qflist" })

local next_ai_notes, prev_ai_notes = RepeatablePairs.track_pair(function()
  require("scripts.ui.claude-qf-notes.navigate").cycle(1, { copen = false })
end, function()
  require("scripts.ui.claude-qf-notes.navigate").cycle(-1, { copen = false })
end)

map("n", "<leader>ij", next_ai_notes, { desc = "Next (newer) ai notes" })
map("n", "<leader>ik", prev_ai_notes, { desc = "Prev. (older) ai notes" })

map("n", "<leader>i/", function()
  require("scripts.ui.claude-qf-notes.navigate").pick({ copen = false })
end, { desc = "Pick ai notes by title" })

map("n", "<leader>ix", function()
  require("scripts.ui.claude-qf-notes.expand-note").peek()
end, { desc = "Peek ai note as real text" })

map("n", "<leader>iq", function()
  require("scripts.ui.claude-qf-notes.navigate").clear()
end, { desc = "Clear ai notes" })

-- search visual selection in snacks explorer
map("x", "<leader>se", function()
  require("scripts.ux.open-selection-in-picker").open_selection_in_explorer()
end, { desc = "Open selection in explorer", icon = "󱥰" })

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

map({ "n", "x" }, "<leader>ua", unalign, { desc = "Unalign: collapse multi-spaces" })

-- Run current file ?? (pwsh safe, unsure about why we need the `&` now...)
map("n", "<leader>uR", function()
  vim.cmd('!& "' .. vim.fn.expand("%:p") .. '"')
end, { desc = "Run script", icon = "🚀" })

-- Close all buffers except current one
map("n", "<leader>uX", function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= vim.api.nvim_get_current_buf() then
      vim.api.nvim_buf_delete(buf, {})
    end
  end
end, { desc = "Close all other buffers", icon = "❌" })

-- Pipe git diffs to clipboard
local pipe_git_diff = require("scripts.ux.pipe-git-diff-to-clip")
map("n", "<leader>g<leader>f", function()
  pipe_git_diff.file_diff()
end, {
  silent = true,
  desc = "Copy file git diff",
  icon = { icon = "", hl = "DevIconGitLogo" },
})

map("n", "<leader>g<leader>F", function()
  pipe_git_diff.file_diff({ staged = true })
end, {
  silent = true,
  desc = "Copy file diff (incl. staged)",
  icon = { icon = "", hl = "DevIconGitLogo" },
})

map("n", "<leader>g<leader>d", function()
  pipe_git_diff.cwd_diff()
end, {
  silent = true,
  desc = "Copy cwd git diff",
  icon = { icon = "", hl = "DevIconGitLogo" },
})

map("n", "<leader>g<leader>D", function()
  pipe_git_diff.cwd_diff({ staged = true })
end, {
  silent = true,
  desc = "Copy cwd diff (incl. staged)",
  icon = { icon = "", hl = "DevIconGitLogo" },
})

map("n", "<leader>g<leader>q", function()
  pipe_git_diff.qf_list()
end, {
  silent = true,
  desc = "Copy quickfix git diff",
  icon = { icon = "", hl = "DevIconGitLogo" },
})

map("n", "<leader>g<leader>Q", function()
  pipe_git_diff.qf_list({ staged = true })
end, {
  silent = true,
  desc = "Copy qf diff (incl. staged)",
  icon = { icon = "", hl = "DevIconGitLogo" },
})

-- show path of current buffer/cwd in floating window
map("n", "<leader>uP", function()
  require("scripts.ui.show-buffer-fullpath").show_fullpath()
end, { desc = "Show current buffer full path", icon = "󰇘" })

map("n", "<leader>up", function()
  require("scripts.ui.show-buffer-fullpath").show_fullpath_cwd()
end, { desc = "Show buffer path (git root)", icon = "󰇘" })

map("n", "<leader>u.", function()
  require("scripts.ui.show-buffer-fullpath").show_cwd()
end, { desc = "Show current cwd" })

-- toggle a window into a maximized floating one
map({ "n", "t", "i" }, "<m-m>", function()
  require("scripts.ux.maximize-to-float").toggle_max_float()
end, { desc = "Toggle maximized terminal", icon = "" })
