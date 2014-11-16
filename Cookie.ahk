#Include lib\Console.ahk
Console.SetFont(12,16)
Console.SetSize(16,10)
MyYoshi := new Yoshi(4, 8)
MyYoshi.Print()
SetTimer, MyYoshi, 750
return

MyYoshi:
MyYoshi.Step()
MyYoshi.Print()
SetTimer, MyYoshi, % Hyperspeed ? 50 : 750
return

MsgBox
#if WinActive("ahk_id " Console.hWnd)
left::MyYoshi.MoveUser(-1), MyYoshi.Print()
Right::MyYoshi.MoveUser(1), MyYoshi.Print()
Space::MyYoshi.SwapCols(), MyYoshi.Print()
Down::
Hyperspeed := True
gosub MyYoshi
KeyWait, Down
return
Down Up::Hyperspeed := false
;MyYoshi.Step(),MyYoshi.Print()
Escape::ExitApp
class Yoshi
{
	__New(Width, Height)
	{
		this.Width := Width
		this.Height := Height
		
		; Initialize player
		this.PlayerX := 1
		
		; Initialize board
		this.Board := []
		Loop, % Width
		{
			x := A_Index
			Loop, % Height
				this.Board[x, A_Index] := 0
		}
		
		; Initialize falling items
		this.FallingY := 1
		this.Falling := []
		Loop, % Width
			this.Falling[A_Index] := 0
		this.NewFalling()
		
		this.Buffer := new ConsoleBuffer(Width, Height+1)
		this.Print()
	}
	
	MoveUser(Direction)
	{
		if (Direction == 1)
		{
			if (this.PlayerX < this.Width-1)
				this.PlayerX++
		}
		else if (Direction == -1)
		{
			if (this.PlayerX > 1)
				this.PlayerX--
		}
	}
	
	Step()
	{
		global Hyperspeed
		if !this.Drop()
		{
			if !this.NewFalling()
			{
				MsgBox, duhbonk, ya lost
				;this.reset()
			}
			HyperSpeed := false
		}
		
	}
	
	NewFalling()
	{
		this.FallingY := 1
		Random, Rand, 1, 4
		Spots := [1,2,3,4]
		Loop, % Rand
		{
			Random, Type, 1, 4
			Random, Spot, 1, Spots.MaxIndex()
			this.Falling[Spots.Remove(Spot)] := Type
		}
		
		return !this.Collides()
	}
	
	Collides()
	{
		for x, Col in this.Board
			if (this.Falling[x] && Col[this.FallingY])
				return True
	}
	
	Drop()
	{
		StillFalling := this.Settle()
		if StillFalling
			this.FallingY++
		return StillFalling
	}
	
	Settle()
	{
		StillFalling := false ; No known items still falling
		for x, Col in this.Board
		{
			if this.Falling[x]
			{
				if (this.FallingY >= this.Height) ; At bottom
				{
					Col[this.FallingY] := this.Falling[x]
					this.Falling[x] := 0
				}
				else if (Col[this.FallingY+1]) ; Fell on something
				{
					if (Col[this.FallingY+1] == this.Falling[x]) ; Fell on same thing
					{
						; Remove both items
						Col[this.FallingY+1] := 0
						this.Falling[x] := 0
					}
					else ; Fell on different thing
					{
						; Settle item
						Col[this.FallingY] := this.Falling[x]
						this.Falling[x] := 0
					}
				}
				else
					StillFalling := True ; There is at least one item still falling
			}
		}
		return StillFalling
	}
	
	SwapCols()
	{
		x := this.PlayerX
		
		; Swap columns
		t := this.Board[x]
		this.Board[x] := this.Board[x+1]
		this.Board[x+1] := t
		
		; Push falling objects out of the way
		for x, SwapDir in Object(x, 1, x+1, -1)
		{
			for y, Piece in this.Board[x]
			{
				if (y == this.FallingY && Piece && this.Falling[x])
				{
					t := this.Falling[x]
					this.Falling[x] := this.Falling[x+SwapDir]
					this.Falling[x+SwapDir] := t
				}
			}
		}
	}
	
	Print()
	{
		this.Buffer.Clear()
		
		; Print fallen objects
		for x, Col in this.Board
			for y, Piece in Col
				if Piece
					this.Buffer.Set(x, y, Chr(2+Piece), Piece)
		
		; Print falling objects
		for x, Piece in this.Falling
			if Piece
				this.Buffer.Set(x, this.FallingY, Chr(2+Piece), Piece+8)
		
		; Print player
		x := this.PlayerX
		y := this.Height+1
		this.Buffer.Set(x, y, "└", Console.colors.Red)
		this.Buffer.Set(x+1, y, "┘", Console.colors.Red)
		
		Console.WriteOutput(this.Buffer, [1,1,this.Width,this.Height+1])
	}
}

Rand(Min, Max)
{
	Random, Rand, Min, Max
	return Rand
}