//
//	SETCONSOLEINFO.C
//
//	Undocumented method to set console attributes
//  at runtime including console palette (NT4, 2000, XP).
//
//	VOID WINAPI SetConsolePalette(COLORREF palette[16])
//
//	For Vista use the newly documented SetConsoleScreenBufferEx API
//
//	www.catch22.net
//
#include <windows.h>
#include <stdio.h>
#include <stdarg.h>

// only in Win2k+  (use FindWindow for NT4)
HWND WINAPI GetConsoleWindow();

// Undocumented console message
#define WM_SETCONSOLEINFO			(WM_USER+201)

#pragma pack(push, 1)

//
//	Structure to send console via WM_SETCONSOLEINFO
//
typedef struct _CONSOLE_INFO
{
	ULONG		Length;
	COORD		ScreenBufferSize;
	COORD		WindowSize;
	ULONG		WindowPosX;
	ULONG		WindowPosY;

	COORD		FontSize;
	ULONG		FontFamily;
	ULONG		FontWeight;
	WCHAR		FaceName[32];

	ULONG		CursorSize;
	ULONG		FullScreen;
	ULONG		QuickEdit;
	ULONG		AutoPosition;
	ULONG		InsertMode;
	
	USHORT		ScreenColors;
	USHORT		PopupColors;
	ULONG		HistoryNoDup;
	ULONG		HistoryBufferSize;
	ULONG		NumberOfHistoryBuffers;
	
	COLORREF	ColorTable[16];

	ULONG		CodePage;
	HWND		Hwnd;

	WCHAR		ConsoleTitle[0x100];

} CONSOLE_INFO;

#pragma pack(pop)

//
//	Wrapper around WM_SETCONSOLEINFO. We need to create the
//  necessary section (file-mapping) object in the context of the
//  process which owns the console, before posting the message
//
BOOL SetConsoleInfo(HWND hwndConsole, CONSOLE_INFO *pci)
{
	DWORD   dwConsoleOwnerPid;
	HANDLE  hProcess;
	HANDLE	hSection, hDupSection;
	PVOID   ptrView = 0;
	HANDLE  hThread;
	
	//
	//	Open the process which "owns" the console
	//	
	GetWindowThreadProcessId(hwndConsole, &dwConsoleOwnerPid);
	
	hProcess = OpenProcess(MAXIMUM_ALLOWED, FALSE, dwConsoleOwnerPid);

	//
	// Create a SECTION object backed by page-file, then map a view of
	// this section into the owner process so we can write the contents 
	// of the CONSOLE_INFO buffer into it
	//
	hSection = CreateFileMapping(INVALID_HANDLE_VALUE, 0, PAGE_READWRITE, 0, pci->Length, 0);

	//
	//	Copy our console structure into the section-object
	//
	ptrView = MapViewOfFile(hSection, FILE_MAP_WRITE|FILE_MAP_READ, 0, 0, pci->Length);

	memcpy(ptrView, pci, pci->Length);

	UnmapViewOfFile(ptrView);

	//
	//	Map the memory into owner process
	//
	DuplicateHandle(GetCurrentProcess(), hSection, hProcess, &hDupSection, 0, FALSE, DUPLICATE_SAME_ACCESS);

	//  Send console window the "update" message
	SendMessage(hwndConsole, WM_SETCONSOLEINFO, (WPARAM)hDupSection, 0);

	//
	// clean up
	//
	hThread = CreateRemoteThread(hProcess, 0, 0, (LPTHREAD_START_ROUTINE)CloseHandle, hDupSection, 0, 0);

	CloseHandle(hThread);
	CloseHandle(hSection);
	CloseHandle(hProcess);

	return TRUE;
}

//
//	Fill the CONSOLE_INFO structure with information
//  about the current console window
//
static void GetConsoleSizeInfo(CONSOLE_INFO *pci)
{
	CONSOLE_SCREEN_BUFFER_INFO csbi;

	HANDLE hConsoleOut = GetStdHandle(STD_OUTPUT_HANDLE);

	GetConsoleScreenBufferInfo(hConsoleOut, &csbi);

	pci->ScreenBufferSize = csbi.dwSize;
	pci->WindowSize.X	  = csbi.srWindow.Right - csbi.srWindow.Left + 1;
	pci->WindowSize.Y	  = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
	pci->WindowPosX	      = csbi.srWindow.Left;
	pci->WindowPosY		  = csbi.srWindow.Top;
}

//
// Set palette of current console
//
//	palette should be of the form:
//
// COLORREF DefaultColors[16] = 
// {
//	0x00000000, 0x00800000, 0x00008000, 0x00808000,
//	0x00000080, 0x00800080, 0x00008080, 0x00c0c0c0, 
//	0x00808080,	0x00ff0000, 0x0000ff00, 0x00ffff00,
//	0x000000ff, 0x00ff00ff,	0x0000ffff, 0x00ffffff
// };
//
VOID WINAPI SetConsolePalette(COLORREF palette[16])
{
	CONSOLE_INFO ci = { sizeof(ci) };
	int i;
        HWND hwndConsole = GetConsoleWindow();

	// get current size/position settings rather than using defaults..
	GetConsoleSizeInfo(&ci);

	// set these to zero to keep current settings
	ci.FontSize.X				= 0;//8;
	ci.FontSize.Y				= 0;//12;
	ci.FontFamily				= 0;//0x30;//FF_MODERN|FIXED_PITCH;//0x30;
	ci.FontWeight				= 0;//0x400;
	//lstrcpyW(ci.FaceName, L"Terminal");
	ci.FaceName[0]				= L'\0';

	ci.CursorSize				= 25;
	ci.FullScreen				= FALSE;
	ci.QuickEdit				= TRUE;
	ci.AutoPosition				= 0x10000;
	ci.InsertMode				= TRUE;
	ci.ScreenColors				= MAKEWORD(0x7, 0x0);
	ci.PopupColors				= MAKEWORD(0x5, 0xf);
	
	ci.HistoryNoDup				= FALSE;
	ci.HistoryBufferSize		= 50;
	ci.NumberOfHistoryBuffers	= 4;

	// colour table
	for(i = 0; i < 16; i++)
		ci.ColorTable[i] = palette[i];

	ci.CodePage					= 0;//0x352;
	ci.Hwnd						= hwndConsole;

	lstrcpyW(ci.ConsoleTitle, L"");

	SetConsoleInfo(hwndConsole, &ci);
}



