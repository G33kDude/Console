;#Include %A_LineFile%\..\lib\Console.ahk
#SingleInstance, prompt
#Include <Console>
#Include Commands.ahk
SetBatchLines, -1

FileRead, File, %A_LineFile%

NormalColor := Chr(3) Chr(Console.Colors.White)

Operators := "\+|-|\*|!|~|&|/|<|>|\^|\||=|&&|\|\||\?|:|\(|\)|,|%"
File := RegExReplace(File, "\R", "`n")
File := RegExReplace(File, "i)((?:" Operators ")+)", Chr(3) Chr(Console.Colors.Aqua) "$1" NormalColor)
File := RegExReplace(File, "m`n)^(\s*#[^\s,\R]+)", Chr(3) Chr(Console.Colors.Teal) "$1" NormalColor)
File := RegExReplace(File, "\b(0x[0-9A-F]+|\d+)\b", Chr(3) Chr(Console.Colors.Fuchsia) "$1" NormalColor)

for type, words in Commands
{
	if Type in Flow,Indent
		NewColor := Chr(3) Chr(Console.Colors.Lime)
	else
		NewColor := Chr(3) Chr(Console.Colors.Yellow)
	
	StringReplace, Words, Words, %A_Space%, |, All
	File := RegExReplace(File, "i)\b(" Words ")\b", NewColor "$1" NormalColor)
}

File := StrSplit(File)
Console.SetColor("White")
Quoted := false, Commented := false
Last := "`n" ; This lets me put comments and similar on the first line in the file.
; This is a comment with "quotes" in it
While (Char := File.Remove(1)) != ""
{
	if (Asc(Char) == 3)
	{
		NewColor := Asc(File.Remove(1))
		if (!Quoted && !Commented)
			Console.SetColor(NewColor)
	}
	else
	{
		if (Char == "`n") ; Newline
			Quoted := False, Commented := False, Console.SetColor("White")
		else if (Char == """" && !Commented)
			Quoted := !Quoted, Console.SetColor("Red")
		else if (Char == ";" && InStr(" `t`n", Last))
			Commented := True, Quoted := False, Console.SetColor("Green")
		
		Console.Print(Char)
		
		Last := Char
	}
}
MsgBox