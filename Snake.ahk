#Include lib\Console.ahk

class Snake
{
	__New(Width, Height)
	{
		this.Width := Width
		this.Height := Height
		this.Buffer := new ConsoleBuffer(Width, Height)
		this.Snake := []
		
		this.Grid := []
		loop, % this.Width
		{
			x := A_Index
			loop, % this.Height
			{
				y := A_Index
				this.Grid[x, y] := new this.Tile(x, y)
			}
		}
		
		loop, 5 ; Snake length
		{
			x := Width // 2
			y := Height // 2 + A_Index - 1
			Tile := this.Grid[x, y]
			Tile.Symbol := A_Index == 1 ? "O" : "X"
			this.Snake[A_Index] := Tile
		}
	}
	
	GeneratePellet()
	{
		loop
		{
			Random, NewX, 1, this.Width
			Random, NewY, 1, this.Height
			Tile := this.Grid[NewX, NewY]
		}
		until Tile.Type == "Blank"
		Random, Color, 9, 14
		Tile.Type := "Pellet"
		Tile.Color := Color
	}
	
	Move(DirX, DirY)
	{
		NewX := Snake[1].x + DirX
		NewY := Snake[1].y + DirY
		this.SwapTiles(this.Grid[NewX, NewY], Snake[1])
		loop, % Snake.MaxIndex()-1
		{
			Snake[A_Index+1] := Snake[A_Index]
		}
		
		Snake[1] := [NewX, NewY]
	}
	
	SwapTiles(Tile1, Tile2)
	{
		this.Grid[Tile1.x, Tile1.y] := Tile2
		this.Grid[Tile2.x, Tile2.y] := Tile1
		TmpY := Tile1.x, TmpY := Tile1.y
		Tile1.x := tile2.x, Tile1.y := Tile2.y
		Tile2.x := TmpX, Tile2.y := TmpY
	}
	
	class Tile
	{
		__New(x, y, Type="Blank", Symbol=" ", Color=0)
		{
			this.x := x
			this.y := y
			this.Type := Type
			this.Symbol := Symbol
			this.Color := Color
		}
	}
}