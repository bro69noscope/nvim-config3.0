_G.SwapLineUpBind = "<c-K>"
_G.SwapLineDownBind = "<c-J>"

if OnNeovide then
  _G.SwapLineUpBind = "<c-s-k>"
  _G.SwapLineDownBind = "<c-s-j>"
end

_G.NextDiffChangeBind = "<m-j>"
_G.PrevDiffChangeBind = "<m-k>"
_G.NextDiffConflictBind = "<m-J>"
_G.PrevDiffConflictBind = "<m-K>"

_G.HideTerminalBind = "<c-o>"

_G.UpWindowBind = "<c-k>"
_G.DownWindowBind = "<c-j>"
_G.LeftWindowBind = "<c-h>"
_G.RightWindowBind = "<c-l>"

_G.MacroBind = "Z"
_G.ToggleClaudeBind = "<m-s>"
_G.ToggleClaudeBindNoFocus = "<m-t>" -- no focus mode
_G.ToggleExplorerBind = "<m-n>" -- no focus mode

_G.PickProjectBind = "<leader>p"
