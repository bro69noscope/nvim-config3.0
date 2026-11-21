-- WezTerm sends ctrl+shift+key as CSI u (see ../wezterm/nvim.lua ctrl_shift), Neovide sends it
-- natively: both give <c-s-key>.
_G.SwapLineUpBind = "<c-s-k>"
_G.SwapLineDownBind = "<c-s-j>"
_G.SaveAllBind = "<c-s-s>"

_G.NextDiffChangeBind = "<m-j>"
_G.PrevDiffChangeBind = "<m-k>"
_G.NextDiffConflictBind = "<m-s-j>"
_G.PrevDiffConflictBind = "<m-s-k>"

_G.HideTerminalBind = "<c-o>"

_G.UpWindowBind = "<c-k>"
_G.DownWindowBind = "<c-j>"
_G.LeftWindowBind = "<c-h>"
_G.RightWindowBind = "<c-l>"

_G.MacroBind = "Z" -- `q`/`Q` are widely used as "quit/quit alternatively" in the config
_G.ToggleClaudeBind = "<m-s>"
_G.ToggleClaudeBindNoFocus = "<m-t>" -- no focus mode
_G.ToggleExplorerBind = "<m-n>" -- no focus mode

_G.PickProjectBind = "<leader>p"
