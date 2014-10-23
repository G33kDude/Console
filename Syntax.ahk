;#Include %A_LineFile%\..\lib\Console.ahk
#SingleInstance, prompt
#Include <Console>
#Include Commands.ahk
SetBatchLines, -1

FileRead, File, %A_LineFile%

NormalColor := Console.Colors.White

File := RegExReplace(File, "\R", "`n")
Regexes := {"i)([+*!~&/<>^|=?:,.%(){}\[\]\-]+)": Console.Colors.Aqua
, "m`n)^(\s*#[^\s,\R]+)": Console.Colors.Teal, "\b(0x[0-9A-F]+|\d+)\b": Console.Colors.Fuchsia}
for Regex, NewColor in Regexes
	File := RegExReplace(File, Regex, Chr(3) Chr(NewColor) "$1" Chr(3) Chr(NormalColor))

for Type, Words in Commands
{
	if Type in Flow,Indent
		NewColor := Chr(3) Chr(Console.Colors.Lime)
	else
		NewColor := Chr(3) Chr(Console.Colors.Yellow)
	
	StringReplace, Words, Words, %A_Space%, |, All
	File := RegExReplace(File, "i)\b(" Words ")\b", NewColor "$1" Chr(3) Chr(NormalColor))
}

File := StrSplit(File)
Console.SetColor(NormalColor)
Quoted := false, Commented := false
Last := "`n" ; This lets me put comments and similar on the first line in the file.
While ((Char := File.Remove(1)) != "")
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
			Quoted := False, Commented := False, Console.SetColor(NormalColor)
		else if (Char == """" && !Commented) ; This is a comment with "quotes" in it
			Quoted := !Quoted, Console.SetColor("Red")
		else if (Char == ";" && InStr(" `t`n", Last))
			Commented := True, Quoted := False, Console.SetColor("Green")
		
		Console.Print(Char)
		
		if (Char == """" && !Commented && !Quoted)
			Console.SetColor(NormalColor)
		
		Last := Char
	}
}
MsgBox