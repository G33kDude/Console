;#Include %A_LineFile%\..\lib\Console.ahk
#SingleInstance, prompt
#Include <Console>
#Include Commands.ahk
SetBatchLines, -1

FileRead, File, %A_LineFile%

Operators := "\+|-|\*|!|~|&|/|<|>|\^|\||=|&&|\|\||\?|:|\(|\)|,"
File := RegExReplace(File, "\R", "`n")
File := RegExReplace(File, "i)((?:" Operators ")+)", Chr(3) Chr(Console.Colors.Aqua) "$1" Chr(3) Chr(Console.Colors.White))
File := RegExReplace(File, "m`n)^(\s*#[^\s,\R]+)", Chr(3) Chr(Console.Colors.Teal) "$1" Chr(3) Chr(Console.Colors.White))
File := RegExReplace(File, "m`n)((^|\s+);)", Chr(3) Chr(Console.Colors.Green) "$1")
File := RegExReplace(File, "(""[^""]*"")", Chr(3) Chr(Console.Colors.Red) "$1" Chr(3) Chr(Console.Colors.White))
File := RegExReplace(File, "\b(0x[0-9A-F]+|\d+)\b", Chr(3) Chr(Console.Colors.Fuchsia) "$1" Chr(3) Chr(Console.Colors.White))

for type, words in Commands
{
	if Type in Flow,Indent
		Color := Chr(3) Chr(Console.Colors.Lime)
	else
		Color := Chr(3) Chr(Console.Colors.Yellow)
	
	StringReplace, Words, Words, %A_Space%, |, All
	File := RegExReplace(File, "i)\b(" Words ")\b", Color "$1" Chr(3) Chr(Console.Colors.White))
}

File := StrSplit(File)
Console.SetColor("White")
Quoted := false, Commented := false
Last := "`n" ; This lets me put comments and similar on the first line in the file
While (Char := File.Remove(1)) != ""
{
	if (Asc(Char) == 3)
	{
		Color := Asc(File.Remove(1))
		if (!Quoted && !Commented)
			Console.SetColor(Color)
	}
	else
	{
		Ascii := Asc(Char)
		if (Ascii == 10)
			Quoted := False, Commented := False, Console.SetColor("White")
		else if (Ascii == 34)
			Quoted := !Quoted
		else if (Ascii == 59 && InStr(" `t`n", Last))
			Commented := True, Console.SetColor("Green")
		
		Console.Print(Char)
		Last := Char
	}
}
MsgBox