_G.NextDiffChangeBind = "<m-j>"
_G.PrevDiffChangeBind = "<m-k>"
_G.NextDiffConflictBind = "<c-J>"
_G.PrevDiffConflictBind = "<c-K>"

if OnNeovide then
  _G.NextDiffConflictBind = "<c-s-j>"
  _G.PrevDiffConflictBind = "<c-s-k>"
end

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
