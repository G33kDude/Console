class Console
{
	static Handle := DllCall("GetStdHandle", "UInt", (-11,DllCall("AllocConsole")), "UPtr")
	static hWnd := DllCall("GetConsoleWindow")
	static Colors := {"Black":0,"Navy":1,"Green":2,"Teal":3,"Maroon":4,"Purple":5,"Olive":6
	,"Silver":7,"Gray":8,"Blue":9,"Lime":10,"Aqua":11,"Red":12,"Fuchsia":13,"Yellow":14,"White":15}
	
	SetFont(w, h)
	{
		Loop, % DllCall("GetNumberOfConsoleFonts")
		{
			Coord := DllCall("GetConsoleFontSize", "UPtr", Console.Handle, "UInt", A_Index-1)
			dH := Coord>>16 & 0xFF, dW := Coord & 0xFF
			if (dW == w && dH == h)
				return DllCall("SetConsoleFont", "UPtr", Console.Handle, "UInt", A_Index-1)
		}
		throw Exception("Size not found")
	}
	
	class _CONSOLE_FONT
	{
		__New(Address)
		{
			this.index := NumGet(Address+0, "UInt")
			this.dimW := NumGet(Address+4, "UShort")
			this.dimH := NumGet(Address+6, "UShort")
		}
	}
	
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
		VarSetCapacity(x, 96, 0)
		NumPut(96, x, "UInt")
		DllCall("GetConsoleScreenBufferInfoEx", "UPtr", this.Handle, "UPtr", &x)
		Data := this.Get_CONSOLE_SCREEN_BUFFER_INFOEX(&x)
		Data.srWindow := [0,0,Width,Height]
		Data.dwSize := [Width,Height]
		this.SET_CONSOLE_SCREEN_BUFFER_INFOEX(&x, Data)
		DllCall("SetConsoleScreenBufferInfoEx", "UPtr", this.Handle, "UPtr", &x)
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
	
	Get_POINT(Address)
	{
		return [NumGet(Address+0, "UShort"), NumGet(Address+2, "UShort")]
	}
	
	Get_CONSOLE_SCREEN_BUFFER_INFOEX(Address)
	{
		if (NumGet(Address+0, "UInt") != 96)
			throw Exception("Something is wrong here")
		ColorTable := []
		Loop, 16
		{
			Color := NumGet(Address+32 + (A_Index-1) * 4, "UInt")
			ColorTable[A_Index] := [(Color>>16)&0xFF, (Color>>8)&0xFF, (Color)&0xFF]
		}
		return {cbSize: NumGet(Address+0, "UInt")
		, dwSize: this.Get_POINT(Address+4)
		, dwCursorPos: this.Get_POINT(Address+8)
		, wAttributes: NumGet(Address+12, "UShort")
		, srWindow: this.Get_SMALL_RECT(Address+14)
		, dwMaxWinSize: this.Get_POINT(Address+22)
		, wPopupAttributes: NumGet(Address+26, "UShort")
		, bFullscreenSupported: NumGet(Address+28, "UInt")
		, ColorTable: ColorTable}
	}
	
	Set_CONSOLE_SCREEN_BUFFER_INFOEX(Address, Object)
	{
		NumPut(Object.cbSize, Address+0, "UInt")
		NumPut(Object.dwSize[1], Address+4, "UShort")
		NumPut(Object.dwSize[2], Address+6, "UShort")
		NumPut(Object.dwCursorPos[1], Address+8, "UShort")
		NumPut(Object.dwCursorPos[2], Address+10, "UShort")
		NumPut(Object.wAttributes, Address+12, "UShort")
		NumPut(Object.srWindow[1], Address+14, "UShort")
		NumPut(Object.srWindow[2], Address+16, "UShort")
		NumPut(Object.srWindow[3], Address+18, "UShort")
		NumPut(Object.srWindow[4], Address+20, "UShort")
		NumPut(Object.dwMaxWinSize[1], Address+22, "UShort")
		NumPut(Object.dwMaxWinSize[2], Address+24, "UShort")
		NumPut(Object.wPopupAttributes, Address+26, "UShort")
		NumPut(Object.bFullscreenSupported, Address+28, "UInt")
		for Index, Color in ColorTable
			NumPut((Color[1]&0xFF)<<16|(Color[2]&0xFF)<<8|(Color[1]&0xFF), Address+32 + (Index-1)*4, "UInt")
	}
	
	Get_SMALL_RECT(Address)
	{
		return [NumGet(Address+0, "UShort")
		, NumGet(Address+2, "UShort")
		, NumGet(Address+4, "UShort")
		, NumGet(Address+6, "UShort")]
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