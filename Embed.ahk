#Include %A_LineFile%\..
#Include lib\Console.ahk
DetectHiddenWindows, On

WS_CAPTION := 0xC00000, WS_SIZEBOX := 0x40000
WS_EX_CLIENTEDGE := 0x200, WS_CLIPCHILDREN := 0x2000000

BufferSize := [80, 40]
FontSize := [8, 8]

MsgBox, % Console.SetFont(FontSize*)
Console.SetSize(BufferSize*)

GuiWidth := BufferSize[1] * FontSize[1]
GuiHeight := BufferSize[2] * FontSize[2]

Gui, +hWndhWnd
Gui, Show, w%GuiWidth% h%GuiHeight%

SetStyle("ahk_id " Console.hWnd, 0, WS_CAPTION|WS_SIZEBOX, 0, WS_EX_CLIENTEDGE)
SetStyle("ahk_id " hWnd, WS_CLIPCHILDREN)
DllCall("SetParent", "UInt", Console.hWnd, "UInt", hWnd)
WinMove, % "ahk_id " Console.hWnd,, 0, 0

#Include Syntax.ahk

GuiClose:
ExitApp
return

SetStyle(Window, Add=0, Remove=0, AddEx=0, RemoveEx=0)
{
	if Add
		WinSet, Style, +%Add%, %Window%
	if Remove
		WinSet, Style, -%Remove%, %Window%
	if AddEx
		WinSet, ExStyle, +%AddEx%, %Window%
	if RemoveEx
		WinSet, ExStyle, -%RemoveEx%, %Window%
}