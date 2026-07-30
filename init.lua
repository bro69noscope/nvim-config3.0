_G.OnWindows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
_G.Logger = require("config.custom-logging")
_G.RepeatablePairs = require("config.repeatable-pairs")
_G.StreamingLayout = require("config.streaming_layout")
_G.OnNeovide = require("config.neovide")

Logger.init()
Logger.set_level("DEBUG")
RepeatablePairs.setup()
NextDiffChangeBind = "<c-g>"
PreviousDiffChangeBind = "<c-m>"
HideTerminalBind = "<c-u>"

require("config.options")
require("config.lazy")
vim.cmd([[colorscheme tokyonight-storm]])
require("config.keymaps")
require("config.autocmds")
require("config.highlight-groups")
require("config.lsp-settings")
require("config.custom-logging")
require("scripts.edit.flip-flop-comments")
require("scripts.edit.swap-true-false-keywords")
require("scripts.edit.edit-path-separators")
require("scripts.ui.resize-windows")
require("scripts.utils.clipboard-functions")
require("scripts.utils.create-float")
require("scripts.utils.various-utils")
require("scripts.ux.delete-mark")
require("scripts.ux.lazygit-terminal")
require("scripts.ux.diagnose-multiple-buffers")
require("scripts.ux.better-tabclose")
require("scripts.ux.find-next-brackets")
