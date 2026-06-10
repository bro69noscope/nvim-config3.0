-- local terms_width = 60
local left_girl_header = ""
local right_girl_header = ""
local headers = nil

local font_size = (tonumber(vim.env.WEZTERM_FONT_SIZE or "12"))
if font_size == 12 then
  headers = require("modules.snacks.dashboard.headers-12-font")
  right_girl_header = headers.right_girl_header
  left_girl_header = headers.left_girl_header
else
  headers = require("modules.snacks.dashboard.headers-11-font")
  right_girl_header = headers.right_girl_header
  left_girl_header = headers.left_girl_header
end

local tiny_header = vim.o.lines < 40
local fullscreen = vim.o.columns >= 190

local function get_panes()
  return {
    left = fullscreen and 1 or nil,
    center = fullscreen and 2 or 1,
    right = fullscreen and 4 or nil,
  }
end

local max_padding = 7
local min_cols = 150
local max_cols = 190

local top_padding = math.max(0, math.min(max_padding, (vim.o.columns - min_cols) / (max_cols - min_cols) * max_padding))

if tiny_header then
  top_padding = -1
end

local panes = get_panes()
return {
  enabled = true,
  width = 42,
  pane_gap = 4,
  preset = {
    keys = {
      {
        icon = "🧠",
        key = "s",
        desc = "Smart Find",
        action = function()
          vim.cmd("lua Snacks.picker.smart()")
        end,
      },
      {
        icon = "📁",
        key = "f",
        desc = "Find File",
        action = function()
          vim.cmd("lua Snacks.picker.files()")
        end,
      },
      {
        icon = "🔤",
        key = "/",
        desc = "Find Word",
        action = function()
          vim.cmd("lua Snacks.picker.grep()")
        end,
      },
      {
        icon = "⌚",
        key = "r",
        desc = "Recent Files",
        action = function()
          vim.cmd("lua Snacks.picker.recent()")
        end,
      },
      {
        icon = "",
        key = "c",
        desc = "Changed files",
        action = function()
          vim.cmd("lua Snacks.picker.git_status()")
        end,
      },
      {
        icon = "📜",
        key = "t",
        desc = "TODO comments",
        action = function()
          vim.cmd("TodoQuickFix keywords=TODO")
        end,
      },
      {
        icon = "💾",
        key = "S",
        desc = "Restore Session",
        section = "session",
      },
      {
        icon = "💤",
        key = "l",
        desc = "Open Lazy",
        action = function()
          vim.cmd("Lazy")
        end,
      },
      {
        icon = { "󰊢 ", hl = "DevIconGitLogo" },
        key = "g",
        desc = "Open LazyGit",
        action = function()
          local lg = require("scripts.ux.lazygit-terminal")
          lg.start_lazygit()
        end,
      },
      {
        icon = { "󱙋 ", hl = "constructor" },
        key = "D",
        desc = "Open DadBodUi",
        action = function()
          local lazy_config = require("lazy.core.config")
          if not lazy_config.plugins["vim-dadbod-ui"] then
            vim.notify("DadBodUi is not installed", vim.log.levels.ERROR)
            return
          end
          require("modules.dadbodui.use-newtab").toggle_dbui_tab()
        end,
      },
      {
        icon = { "󱕖 ", hl = "DevIcon3gp" },
        -- icon = "🗑",
        key = "d",
        desc = "Delete Shada Temp Files",
        enabled = OnWindows,
        action = function()
          require("scripts.utils.delete-temp-shadas").Delete_shada_temp_files()
        end,
      },
      {
        icon = { "✖️", hl = "DevIconAstro" },
        key = "q",
        desc = "Quit Neovim",
        action = function()
          vim.cmd("quit")
        end,
      },
    },
  },
  formats = {
    header = { "%s", align = "left", hl = "@annotation" }, -- Add the hl property here
  },
  sections = {
    {
      pane = panes.left,
      enabled = panes.left ~= nil,
      header = left_girl_header,
    },
    { pane = panes.center, padding = top_padding },
    {
      pane = panes.center,
      header = [[
  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
                                  ..Btw 😎
]],
      enabled = not tiny_header,
      padding = 0,
      width = 25,
    },
    {
      pane = panes.center,
      header = [[
                             _         
      ____  ___  ____ _   __(_)___ ___ 
     / __ \/ _ \/ __ \ | / / / __ `__ \
    / / / /  __/ /_/ / |/ / / / / / / /
   /_/ /_/\___/\____/|___/_/_/ /_/ /_/ 
]],
      enabled = tiny_header,
      padding = 0,
      width = 25,
    },
    { pane = panes.center, section = "keys", gap = 1, padding = 1, width = 15 },
    {
      pane = panes.center,
      icon = " ",
      desc = "Browse Repo on GitHub",
      padding = 1,
      key = "B",
      enabled = function()
        vim.cmd(":setlocal scrolloff=0")
        return Snacks.git.get_root() ~= nil
      end,
      action = function()
        Snacks.gitbrowse()
      end,
    },
    {
      pane = panes.center,
      icon = "󰊢",
      desc = "Not in a Git Repo",
      padding = 1,
      enabled = function()
        return Snacks.git.get_root() == nil
      end,
    },
    {
      pane = panes.center,
      icon = "📂",
      width = 25,
      title = "Recent Files",
      section = "recent_files",
      cwd = true,
      indent = 2,
      padding = 1,
    },
    { pane = panes.center, section = "startup", padding = 900 },
    {
      pane = panes.right,
      enabled = panes.right ~= nil,
      header = right_girl_header,
    },
  },
}
