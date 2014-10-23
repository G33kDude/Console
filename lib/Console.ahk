class Console
{
	static Handle := DllCall("GetStdHandle", "UInt", (-11,DllCall("AllocConsole")), "UPtr")
	static Colors := {"Black":0,"Navy":1,"Green":2,"Teal":3,"Maroon":4,"Purple":5,"Olive":6
	,"Silver":7,"Gray":8,"Blue":9,"Lime":10,"Aqua":11,"Red":12,"Fuchsia":13,"Yellow":14,"White":15}
	
	SetIcon(Path, w=0, h=0)
	{
		if !FileExist(Path)
			throw Exception("File not found")
		
		hIcon := DllCall("LoadImage"
		, "UPtr", 0 ; hInstance (NULL)
		, "Str", Path
		, "UInt", 1 ; uType (IMAGE_ICON)
		, "Int", w ; cxDesired
		, "Int", h ; cyDesired
		, "UInt", 0x10 ; fuLoad (LR_LOADFROMFILE)
		, "UPtr")
		return DllCall("SetConsoleIcon", "UPtr", hIcon)
	}
	
	SetSize(Width, Height)
	{
		Width &= 0xFFFF, Height &= 0xFFFF
		; GOTCHA! Can't set larger window than buffer, can't set smaller buffer than window.
		; If you want to get smaller, shrink the window first.
		; If you want to get larger, grow the buffer first
		; You can work around this by attempting to shrink it both before and after
		
		DllCall("SetConsoleScreenBufferSize", "UPtr", this.Handle, "UInt", Height<<16|Width)
		DllCall("SetConsoleWindowInfo", "UPtr", this.Handle, "Int", True, "UInt64*", this.SMALL_RECT(1,1,Width,Height), "UInt")
		DllCall("SetConsoleScreenBufferSize", "UPtr", this.Handle, "UInt", Height<<16|Width)
	}
	
	SetCursorPos(x, y)
	{
		DllCall("SetConsoleCursorPosition", "UPtr", this.Handle, "UInt", this.POINT(x, y))
	}
	
	Scroll(Rect1, Rect2, Point, Fill)
	{
		VarSetCapacity(CHAR_INFO, 3+A_IsUnicode, 0)
		NumPut(Asc(Fill), CHAR_INFO, 0, A_IsUnicode?"UChar":"UShort")
		DllCall("ScrollConsoleScreenBuffer", "UPtr", this.Handle
		, "UInt64*", this.SMALL_RECT(Rect1*), "UInt64*", this.SMALL_RECT(Rect2*)
		, "UInt", this.POINT(Point*), "UPtr", &CHAR_INFO)
	}
	
	SetColor(FG, BG=0)
	{
		if (FG < 0 || FG > 15)
			FG := this.Colors.HasKey(FG) ? this.Colors[FG] : 15
		if (BG < 0 || BG > 15)
			BG := this.Colors.HasKey(BG) ? this.Colors[BG] : 15
		return DllCall("SetConsoleTextAttribute", "UPtr", this.Handle, "UInt", FG|BG<<4)
	}
	
	ReadInput(Amount)
	{
		InputHandle := DllCall("GetStdHandle", "UInt", -10, "UPtr")
		VarSetCapacity(Buffer, 20*Amount, 0)
		DllCall("PeekConsoleInput", "UPtr", InputHandle
		, "UPtr", &Buffer, "UInt", 1, "UInt*", Read)
		
		if Read
		{
			DllCall("ReadConsoleInput", "UPtr", InputHandle
			, "UPtr", &Buffer, "UInt", Amount, "UInt*", Read)
			Out := []
			Loop, % Read
			{
				Index := (A_Index-1) * 20
				Type := NumGet(Buffer, Index, "UShort")
				if (Type == 1)
					Out.Insert(new this._KEY_EVENT_RECORD(&Buffer+Index+4))
			}
			return Out
		}
	}
	
	Print(Text)
	{
		return FileOpen("CONOUT$", "w").Write(Text)
	}
	
	SMALL_RECT(l,t,r,b)
	{
		l-=1, t-=1, r-=1, b-=1
		return (b&0xFFFF)<<48|(r&0xFFFF)<<32|(t&0xFFFF)<<16|(l&0xFFFF)
	}
	
	POINT(x, y)
	{
		y-=1, x-=1
		return (y&0xFFFF)<<16|(x&0xFFFF)
	}
	
	class _KEY_EVENT_RECORD
	{
		__New(Address)
		{
			this.bKeyDown := NumGet(Address+0, "UInt")
			this.wRepeatCount := NumGet(Address+4, "UShort")
			this.wVirtualKeyCode := NumGet(Address+6, "UShort")
			this.wVirtualScanCode := NumGet(Address+8, "UShort")
			this.UnicodeChar := NumGet(Address+10, "UShort")
			this.dwControlKeyState := NumGet(Address+12, "UInt")
		}
	}
}