; Run by lua/lang/markdown/obsidian.lua after it opens an obsidian:// URI.
; Windows can refuse to give Obsidian the foreground, so this script activates it and clicks in it
; to give keyboard focus to the editor.
#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
#WinActivateForce

; per-monitor-v2: physical pixels on every monitor, also with mixed DPI
DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")

hwnd := WinWait("ahk_exe Obsidian.exe", , 10)
if !hwnd {
  FileAppend("Obsidian window not found after 10 s`n", "**")
  ExitApp(1)
}

WinActivate(hwnd)
if !WinWaitActive(hwnd, , 2) {
  FileAppend("Obsidian window did not become active`n", "**")
  ExitApp(2)
}

WinGetClientPos(, , &w, &h, hwnd)
; NOTE: consider commenting in if the window focus starts acting up again. Also consider
; the alternating hwnd focus trick that worked for alacrity
;
; Click(w // 2, h - 1)
; Send("{Esc}") ; in case we opened something
