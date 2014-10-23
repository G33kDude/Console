#NoEnv
SetBatchLines, -1

#Include %A_LineFile%\..\lib
#Include Console.ahk

; Pulling from another repo
#Include %A_LineFile%\..\..\MyRC\lib
#Include Socket.ahk
#Include IRCClass.ahk

ConSize := [100,30]
Console.SetSize(ConSize*)
Console.SetCursorPos(1,ConSize[2]-1)
Console.SetColor("White", "Blue")
Console.Print(Pad("=", ConSize[1]-1, "-") "=")
Console.SetColor("White")
Console.SetCursorPos(1,ConSize[2])

Serv := "chat.freenode.net"
Port := 6667
Nick := "MyRConsole"
Pass := ""
Chan := "#botters-test"

MyBot := new Bot()
MyBot.Connect(Serv, Port, Nick, Nick, Nick, Pass)
MyBot.SendJOIN(Chan)

SetTimer, Input, 100
return

Input:
for each, KeyEventRecord in Console.ReadInput(10)
{
	if KeyEventRecord.bKeyDown
	{
		ToolTip, % KeyEventRecord.UnicodeChar
		if (KeyEventRecord.UnicodeChar == 8) ; backspace
		{
			Buffer := SubStr(Buffer, 1, -1)
			Console.SetCursorPos(1, ConSize[2])
			Console.SetColor("White")
			Console.Print(Buffer " ")
		}
		else if (KeyEventRecord.UnicodeChar == 13)
		{
			MyBot.Chat(Chan, Buffer)
			Buffer := ""
			Console.Scroll([1,ConSize[2],ConSize*],[1,ConSize[2],ConSize*],[1,1], " ")
		}
		else if (StrLen(Buffer) < ConSize[1]-1)
		{
			Char := Chr(KeyEventRecord.UnicodeChar)
			Buffer .= Char
			Console.SetColor("White")
			Console.SetCursorPos(1, ConSize[2])
			Console.Print(Buffer)
		}
	}
}
return

Escape::ExitApp

class Bot extends IRC
{
	onPRIVMSG(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		Channel := Params[1]
		AppendChat(NickColor(Nick) ": " Msg)
	}
	
	onCTCP(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		if (Cmd = "ACTION") ; Case insensitive
			AppendChat("* " NickColor(Nick) " " Msg)
	}
	
	onJOIN(Nick,User,Host,Cmd,Params,Msg,Data)
	{
		AppendChat(NickColor(Nick) " just joined " Params[1])
	}
	
	OnDisconnect(Socket)
	{
		ChannelBuffer := []
		for Channel in this.Channels
			ChannelBuffer.Insert(Channel)
		
		AppendChat("Attempting to reconnect: try #1")
		while !this.Connect(this.Server, this.Port, this.DefaultNicks[1], this.DefaultUser, this.Name, this.Pass)
		{
			Sleep, 5000
			AppendChat("Attempting to reconnect: try #" A_Index+1)
		}
		
		this.SendJOIN(ChannelBuffer*)
	}
	
	Chat(Channel, Message)
	{
		Messages := this.SendPRIVMSG(Channel, Message)
		for each, Message in Messages
			AppendChat(NickColor(this.Nick) ": " Message)
		return Messages
	}
}

NickColor(Nick)
{
	for each, Char in StrSplit(Nick)
		Sum += Asc(Char)
	
	Color := Mod(Sum, 12) + 1
	if (Color > 6)
		Color += 2
	
	return Chr(Color) . Nick . Chr(15)
}

AppendChat(Text)
{
	global ConSize
	Console.SetColor("White")
	
	Console.Scroll([1,2,ConSize[1],ConSize[2]-2]
	,[1,1,ConSize[1],ConSize[2]-2],[1,1],"X")
	Console.SetCursorPos(1,ConSize[2]-2)
	
	Pos := [1, ConSize[2]-2]
	Buffer := ""
	for each, Char in StrSplit(Text)
	{
		if (Asc(Char) < 16)
			Console.SetColor(Asc(Char))
		else
		{
			Console.Print(Char), Pos[1]++
			if (Pos[1] > ConSize[1])
			{
				Pos := [1, ConSize[2]-2]
				Console.Scroll([1,2,ConSize[1],ConSize[2]-2]
				,[1,1,ConSize[1],ConSize[2]-2],[1,1],"X")
				Console.SetCursorPos(Pos*)
			}
		}
	}
	
	Console.SetCursorPos(1,ConSize[2])
}

Pad(Text, Len, Padding)
{
	While StrLen(Text) < Len
		Text .= Padding
	return Text
}