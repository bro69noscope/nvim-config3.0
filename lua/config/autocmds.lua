-- remove automatic comment insertion
vim.cmd([[autocmd FileType * set formatoptions-=ro]])

-- Center cursor after search using Enter
vim.api.nvim_create_autocmd("CmdlineEnter", {
  callback = function()
    vim.keymap.set("c", "<CR>", function()
      if vim.fn.getcmdtype() == "/" or vim.fn.getcmdtype() == "?" then
        return "<CR>zz"
      end
      return "<CR>"
    end, { expr = true, buffer = true })
  end,
})

-- Better, floating, command line window
vim.api.nvim_create_autocmd("CmdwinEnter", {
  pattern = "*",
  callback = function()
    -- cmp wont work or cause visual glitches
    vim.b.completion = false
    local buf = vim.api.nvim_get_current_buf()
    local win_id = vim.api.nvim_get_current_win()

    -- quit with q
    vim.keymap.set("n", "q", "<cmd>q<cr>", { buffer = buf, silent = true })

    -- Backspace: close cmdwin but keep its current input in the cmdline
    vim.keymap.set("n", "<BS>", function()
      local line = vim.api.nvim_get_current_line() or ""
      vim.cmd("q")
      -- feedkeys wants termcodes; also escape any special key notation
      local keys = ":" .. vim.fn.escape(line, [[\]])
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", true)
    end, { buffer = buf, silent = true })

    -- float config
    local width = 90
    vim.api.nvim_win_set_config(win_id, {
      relative = "editor",
      width = width,
      height = 15,
      col = math.floor((vim.o.columns - width) / 2 - 1),
      row = math.floor(vim.o.lines * 0.55),
      border = "rounded",
      title = " Cmdline ",
      title_pos = "center",
    })
  end,
})

-- Partial fix for ugly underline in diffs
vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    if vim.wo.diff then
      local wins = vim.api.nvim_tabpage_list_wins(0)
      for _, win in ipairs(wins) do
        vim.wo[win].wrap = false
        vim.wo[win].culopt = "number"
      end
    end
  end,
})

-- Automatically switch to the help window when opening help files to the right side.
-- Needs some extra considerations to avoid bugging out with snacks buffer-grep
_G.processed_help_buffers = _G.processed_help_buffers or {}

local function is_no_neck_pain_active(tabpage)
  tabpage = tabpage or 0
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "no-neck-pain" then
      return true
    end
  end
  return false
end

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "*.txt", "*.md" },
  callback = function(args)
    local bufnr = args.buf
    -- Only process help buffers we haven't seen before (avoid auto-repositioning the buffer when
    -- re-entering it after we moved it manually)
    if vim.bo[bufnr].buftype == "help" and not _G.processed_help_buffers[bufnr] then
      -- Dont move if no-neck-pain is active in this tab
      if not is_no_neck_pain_active() then
        vim.cmd("wincmd L")
      end
      -- Mark this buffer as processed
      _G.processed_help_buffers[bufnr] = true

      -- Set up cleanup when buffer is deleted
      vim.api.nvim_create_autocmd("BufDelete", {
        buffer = bufnr,
        callback = function()
          _G.processed_help_buffers[bufnr] = nil
        end,
        once = true, -- This autocmd can be one-time since it's specific to this buffer
      })
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = vim.tbl_keys(Linelength_by_ft),
  callback = function(args)
    local length = Linelength_by_ft[args.match]
    vim.bo.textwidth = length
  end,
})

-- Define highlighting of spelling errors.
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.opt.spelllang = "en"

    vim.api.nvim_set_hl(0, "SpellBad", {
      underline = true,
      fg = "#ff5555", -- light red
    })

    vim.api.nvim_set_hl(0, "SpellCap", {
      underline = true,
      fg = "#8be9fd", -- light blue
    })

    vim.api.nvim_set_hl(0, "SpellRare", {
      underline = true,
      fg = "#f1fa8c", -- light yellow
    })

    vim.api.nvim_set_hl(0, "SpellLocal", {
      underline = true,
      fg = "#bd93f9", -- light purple
    })
  end,
})

-- Set user var "in_windows_nvim" to "1" in WezTerm via OSC 1337 when entering Neovim on windows.
-- Those vars are used in my wezterm config file to define dynamic pane navigation keybinds, as to
-- use C-hjkl everywhere. On Linux, we run tmux for multiplexing so this is not used.
if OnWindows then
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      local function set_in_windows_nvim(b64_val)
        io.write(string.format("\x1b]1337;SetUserVar=in_Windows_nvim=%s\x07", b64_val))
        io.flush()
      end

      -- set to "1" (MQ==) when Neovim starts
      set_in_windows_nvim("MQ==")

      -- set to "0" (MA==) just before Neovim exits
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          set_in_windows_nvim("MA==")
        end,
      })
    end,
  })
end

-- Send out a name for the terminal title with OSC 0
vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
  callback = function()
    -- Detect operating system and set icon
    local os_name = vim.loop.os_uname().sysname
    local os_icon = ""

    if os_name == "Windows_NT" then
      os_icon = "🪟 "
    elseif os_name == "Linux" then
      os_icon = "🐧"
    else
      os_icon = "[wtf?]"
    end

    local filename = vim.fn.expand("%:t")
    if filename == "" then
      filename = "NoName"
    end

    local title
    if vim.o.columns < 190 then
      title = string.format("%s: %s", os_icon, filename)
    else
      title = string.format("%seovim: %s", os_icon, filename)
    end

    vim.opt.title = true
    vim.opt.titlestring = title
  end,
})

-- Git commit message configuration
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    vim.opt_local.textwidth = 72
    vim.opt_local.colorcolumn = "50,72"
  end,
})

-- Set terminal buffer background color
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.wo.winhighlight = "Normal:CustomTerminalBg"
  end,
})

-- Quit certain buffer types with 'q', though not while in nvim visual multi
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "qf", "oil", "checkhealth", "help", "log", "grug-far" },
  callback = function()
    vim.keymap.set("n", "q", function()
      local vm_active = (vim.g.VM_theme or vim.b.visual_multi)
      if not vm_active then
        vim.cmd("q")
      else
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<Plug>(VM-Skip-Region)", true, false, true),
          "n",
          false
        )
      end
    end, { buffer = true, silent = true })
  end,
})

-- Automatically open main file explorer on startup
local explorer_group = vim.api.nvim_create_augroup("ExplorerAutoOpen", { clear = true })
vim.api.nvim_create_autocmd("BufReadPost", {
  group = explorer_group,
  once = true,
  callback = function()
    vim.defer_fn(function()
      local win_width = vim.api.nvim_win_get_width(0)
      local ft = vim.bo.filetype
      if ft ~= "qf" and ft ~= "dbui" and win_width >= 140 then
        vim.api.nvim_clear_autocmds({ group = explorer_group })
        require("scripts.ui.open-file-explorer").open_main_explorer()
      end
    end, 10)
  end,
})

-- Create a dim backdrop behind Telescope prompt windows
local backdrop = require("scripts.ui.create-backdrop-window")
vim.api.nvim_create_autocmd("FileType", {
  pattern = "TelescopePrompt",
  callback = function()
    local prompt_win = vim.api.nvim_get_current_win()
    local bd = backdrop.open({ blend = 70, zindex = 45 })

    -- clean up when the picker's prompt window closes
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(prompt_win),
      once = true,
      callback = function()
        backdrop.close(bd)
      end,
    })
  end,
})

-- Terminal keymaps
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("GlobalTermKeymaps", { clear = true }),
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set("t", LeftWindowBind, [[<Cmd>wincmd h<CR>]], opts)
    vim.keymap.set("t", DownWindowBind, [[<Cmd>wincmd j<CR>]], opts)
    vim.keymap.set("t", UpWindowBind, [[<Cmd>wincmd k<CR>]], opts)
    vim.keymap.set("t", RightWindowBind, [[<Cmd>wincmd l<CR>]], opts)
    vim.keymap.set("t", "<C-Up>", [[<Cmd>resize +2<CR>]], opts)
    vim.keymap.set("t", "<C-Down>", [[<Cmd>resize -2<CR>]], opts)
    vim.keymap.set("t", "<C-Left>", [[<Cmd>vertical resize -2<CR>]], opts)
    vim.keymap.set("t", "<C-Right>", [[<Cmd>vertical resize +2<CR>]], opts)
    vim.keymap.set("t", ToggleClaudeBind, [[<Cmd>ClaudeCode<CR>]], opts)
  end,
})

-- Show feedback on yank, delete, change in named registers
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("RegFeedback", {}),
  callback = function()
    local reg = vim.v.event.regname
    if reg == "" then
      return
    end -- skip unnamed/default register noise

    local op = vim.v.event.operator
    local verb = (op == "y" and "yanked")
      or (op == "d" and "deleted")
      or (op == "c" and "changed")
      or op

    vim.notify(string.format('%s to "%s', verb, reg), vim.log.levels.INFO)
  end,
})
