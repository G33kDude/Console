#Include lib\Console.ahk

File =
(
; ------------------------------------------------
; ManyTetris Game Template
; ------------------------------------------------
; GAME:  Classic Tetris
; BY:    Icarus

#Rows         20
#Cols         11
#BoxSize      24
#LineScore    10
#PieceScore   2
#PausePenalty 5

#DropSpeed         600
#DropSpeedIncrease 1
#MaxDropSpeed      80
;#DropSpeedPoints   10

---
+++
-+-
=
-+-
-++
-+-
=
-+-
+++
---
=
-+-
++-
-+-

*

----
++++
----
----
=
-+--
-+--
-+--
-+--

*

++-
-++
---
=
-+-
++-
+--

*

-++
++-
---
=
+--
++-
-+-

*

---
+--
+++
=
--+
--+
-++
=
+++
--+
---
=
++-
+--
+--

*

---
--+
+++
=
-++
--+
--+
=
+++
+--
---
=
+--
+--
++-

*

++
++
)

ScriptPID := DllCall("GetCurrentProcessId")


MyTetris := new Tetris(File)

Console.SetOutputCP(437)
Console.SetFont(12, 16)
Console.SetSize(MyTetris.Settings.Cols, MyTetris.Settings.Rows)

Loop
{
	Sleep, % MyTetris.Settings.DropSpeed // 2
	if WinActive("ahk_id " Console.hWnd)
	{
		MyTetris.Step()
		MyTetris.Print()
	}
}
return

#if WinActive("ahk_id " Console.hWnd)

Left::MyTetris.MovePiece(MyTetris.CurX-1, MyTetris.CurY), MyTetris.Print()
Right::MyTetris.MovePiece(MyTetris.CurX+1, MyTetris.CurY), MyTetris.Print()
Up::MyTetris.RotatePiece(1), MyTetris.Print()
Down::
While GetKeyState(A_ThisHotkey, "p")
{
	MyTetris.Step()
	MyTetris.Print()
	Sleep, 50
}
return

#If WinActive("ahk_pid " ScriptPID)
Escape::ExitApp

class Tetris
{
	__New(Settings)
	{
		this.ParseSettings(Settings)
		this.Reset()
	}
	
	Reset()
	{
		this.Buffer := new ConsoleBuffer(this.Settings.Cols, this.Settings.Rows)
		
		this.Score := 0
		
		this.Board := []
		Loop, % this.Settings.Cols
		{
			x := A_Index
			Loop, % this.Settings.Rows
				this.Board[A_Index, x] := 0
		}
		
		this.NewPiece()
	}
	
	NewPiece()
	{
		Random, Rand, 1, this.Pieces.MaxIndex()
		this.CurPiece := Rand
		this.CurRotate := 1
		PieceSize := this.Pieces[Rand, 1].MaxIndex()
		this.CurX := this.Settings.Cols//2 - PieceSize//2
		this.CurY := this.Settings.Rows - PieceSize + 1
		return !this.Collides(this.CurX, this.CurY)
	}
	
	RotatePiece(Amount)
	{
		Tmp := this.CurRotate
		Max := this.Pieces[this.CurPiece].MaxIndex()
		this.CurRotate += Amount
		if (Amount < 0)
			this.CurRotate := this.CurRotate < 1 ? Max : this.CurRotate
		else
			this.CurRotate := this.CurRotate > Max ? 1 : this.CurRotate
		
		if this.Collides(this.CurX, this.CurY)
		{
			this.CurRotate := Tmp
			return false
		}
		return true
	}
	
	Step()
	{
		if !this.MovePiece(this.CurX, this.CurY-1)
		{
			this.Solidify()
			if (Removed := this.RemoveFullLines())
			{
				if (Removed >= 4) ; Tetris! Double points!
					Removed *= 2
				this.Score += Removed * this.Settings.LineScore
			}
			if !this.NewPiece()
			{
				MsgBox, % "GAME OVER!`nScore: " this.Score " Points!"
				this.Reset()
			}
		}
	}
	
	RemoveFullLines()
	{
		Removed := 0
		Loop, % this.Settings.Rows
		{
			Index := this.Settings.Rows - (A_Index - 1)
			if this.LineIsFull(Index)
				this.RemoveLine(index), Removed++
		}
		return Removed
	}
	
	RemoveLine(LineNum)
	{
		Loop, % this.Settings.Rows
			if (A_Index > LineNum)
				this.Board[A_Index-1] := this.Board[A_Index].Clone()
	}
	
	LineIsFull(LineNo)
	{
		for each, Num in this.Board[LineNo]
			if !Num
				return false
		return true
	}
	
	Solidify()
	{
		for y, Row in this.Pieces[this.CurPiece, this.CurRotate]
			for x, PieceNo in Row
				if PieceNo
					this.Board[this.CurY+y-1, this.CurX+x-1] := PieceNo
	}
	
	MovePiece(NewX, NewY)
	{
		if this.Collides(NewX, NewY)
			return false
		
		this.CurX := NewX
		this.CurY := NewY
		
		return true
	}
	
	Collides(NewX, NewY)
	{
		for y, Row in this.Pieces[this.CurPiece, this.CurRotate]
			for x, PieceNo in Row
				if (PieceNo && this.Board[NewY+y-1, NewX+x-1] != 0)
					return true
		return false
	}
	
	Print()
	{
		Out := []
		
		Area := [1,1,this.Settings.Cols, this.Settings.Rows]
		;Console.Scroll(Area, Area, [this.Settings.Cols, this.Settings.Rows], " ")
		this.Buffer.Clear()
		n := this.Settings.Rows + 1
		
		Loop, % this.Settings.Rows
		{
			y := A_Index
			
			Loop, % this.Settings.Cols
			{
				x := A_Index
				if (this.Board[y, x] == 0)
				{
					;Console.SetColor(this.Board[y, x])
					;Console.Print(Chr(0xF9)) ; bullet point
				}
				else
				{
					this.Buffer.Set(x, n-y, Chr(9608), this.Board[y, x]+8)
					;Out[-y, x] := this.Board[y, x]
				}
			}
		}
		
		for y, Row in this.Pieces[this.CurPiece, this.CurRotate]
		{
			for x, PieceNo in Row
			{
				if (PieceNo != 0)
				{
					this.Buffer.Set(this.CurX+x-1, n-(this.CurY+y-1)
					, Chr(9608), this.CurPiece+8)
					;Console.SetCursorPos(this.CurX+x-1, this.CurY+y-1)
					;Console.Print("O")
				}
			}
		}
		
		Console.WriteOutput(this.Buffer, Area)
		;Console.Print(Txt)
	}
	
	ParseSettings(Settings)
	{
		this.Settings := []
		this.Pieces := []
		
		PieceNo := 1
		PieceRotate := 1
		
		for Index, Line in StrSplit(Settings, "`n", "`r")
		{
			if !(Line := Trim(Line))
				continue
			
			FirstChar := SubStr(Line, 1, 1)
			
			if (FirstChar == ";")
				continue
			else if (FirstChar == "#")
			{
				if !RegExMatch(Line, "^#(\S+)\s+(\S+)$", Match)
					throw Exception("Invalid directive format")
				this.Settings[Match1] := Match2
			}
			else if (FirstChar == "=")
				PieceRotate++
			else if (FirstChar == "*")
				PieceRotate := 1, PieceNo++
			else if (Line ~= "^[-+]+$")
			{
				if !IsObject(this.Pieces[PieceNo, PieceRotate])
					this.Pieces[PieceNo, PieceRotate] := []
				
				StringReplace, Line, Line, -, 0, All
				StringReplace, Line, Line, +, %PieceNo%, All
				
				this.Pieces[PieceNo, PieceRotate].Insert(StrSplit(Line))
			}
			else
				throw Exception("Unkown format on line " Index ": " Line)
		}
		
		if !this.Settings.Rows
			this.Settings.Rows := 20
		if !this.Settings.Cols
			this.Settings.Cols := 10
		if !this.Settings.LineScore
			this.Settings.LineScore := 10
	}
}