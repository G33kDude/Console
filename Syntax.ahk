#SingleInstance, Prompt
SetBatchLines, -1
#Include lib\Console.ahk
#Include Commands.ahk

Colors := [0x3f3f3f,0x3F85CD,0x688060,0x80d4aa
,0xbc6c4c,0xbc6c9c,0xccdc90,0xdcdccc
,0x9f9f9f,0x87CEEB,0x9ece9e,0x8cd0d3
,0xf18c96,0xbc8cbc,0xf8f893,0xefefef]

Console.SetFont(8, 8)
Console.SetSize(105, 70)
Console.SetColors(Colors)

FileRead, File, %A_ScriptFullPath%

NormalColor := [Console.Colors.White, Console.Colors.Black]

File := RegExReplace(File, "\R", "`n")
Regexes := {"([+*!~&/<>^|=?:,.%(){}\[\]\-]+)": Console.Colors.Aqua
, "m`n)^(\s*#[^\s,\R]+)": Console.Colors.Teal, "\b(0x[0-9A-Fa-f]+|\d+)\b": Console.Colors.Yellow}
for Regex, NewColor in Regexes
	File := RegExReplace(File, Regex, Chr(3) Chr(NewColor) "$1" Chr(3) Chr(NormalColor[1]))

for Type, Words in Commands
{
	if Type in Flow,Indent
		NewColor := Chr(3) Chr(Console.Colors.Lime)
	else
		NewColor := Chr(3) Chr(Console.Colors.Navy)
	
	StringReplace, Words, Words, %A_Space%, |, All
	File := RegExReplace(File, "i)\b(" Words ")\b", NewColor "$1" Chr(3) Chr(NormalColor[1]))
}

File := StrSplit(File)
Console.SetColor(NormalColor*)
Quoted := false, Commented := false
Last := "`n" ; This lets me put comments and similar on the first line in the file.
While ((Char := File.Remove(1)) != "")
{
	if (Asc(Char) == 3)
	{
		NewColor := Asc(File.Remove(1))
		if (!Quoted && !Commented)
			Console.SetColor(NewColor, NormalColor[2])
	}
	else
	{
		if (Char == "`n") ; Newline
			Quoted := False, Commented := False, Console.SetColor(NormalColor*)
		else if (Char == """" && !Commented) ; This is a comment with "quotes" in it
			Quoted := !Quoted, Console.SetColor("Red", NormalColor[2])
		else if (Char == ";" && InStr(" `t`n", Last))
			Commented := True, Quoted := False, Console.SetColor("Green", NormalColor[2])
		
		Console.Print(Char)
		
		if (Char == """" && !Commented && !Quoted)
			Console.SetColor(NormalColor*)
		
		Last := Char
	}
}
MsgBox