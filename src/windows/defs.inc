ifndef windows_defs_h
windows_defs_h = 1

; functions

extern ExitProcess       : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-findresourcea
; HRSRC FindResourceA(
;   [in, optional] HMODULE hModule,
;   [in]           LPCSTR  lpName,
;   [in]           LPCSTR  lpType
; );
extern FindResourceA     : proto

; https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-loadresource
; HGLOBAL LoadResource(
;   [in, optional] HMODULE hModule,
;   [in]           HRSRC   hResInfo
; );
extern LoadResource      : proto

; https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-lockresource
; LPVOID LockResource(
;   [in] HGLOBAL hResData
; );
extern LockResource      : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registerclassa
; ATOM RegisterClassA(
;   [in] const WNDCLASSA *lpWndClass
; );
extern RegisterClassA    : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-createwindowexa
; HWND CreateWindowExA(
;   [in]           DWORD     dwExStyle,
;   [in, optional] LPCSTR    lpClassName,
;   [in, optional] LPCSTR    lpWindowName,
;   [in]           DWORD     dwStyle,
;   [in]           int       X,
;   [in]           int       Y,
;   [in]           int       nWidth,
;   [in]           int       nHeight,
;   [in, optional] HWND      hWndParent,
;   [in, optional] HMENU     hMenu,
;   [in, optional] HINSTANCE hInstance,
;   [in, optional] LPVOID    lpParam
; );
extern CreateWindowExA   : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-peekmessagea
; BOOL PeekMessageA(
;   [out]          LPMSG lpMsg,
;   [in, optional] HWND  hWnd,
;   [in]           UINT  wMsgFilterMin,
;   [in]           UINT  wMsgFilterMax,
;   [in]           UINT  wRemoveMsg
; );
extern PeekMessageA      : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-translatemessage
; BOOL TranslateMessage(
;   [in] const MSG *lpMsg
; );
extern TranslateMessage  : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-dispatchmessagea
; LRESULT DispatchMessageA(
;   [in] const MSG *lpMsg
; );
extern DispatchMessageA  : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-defwindowproca
; LRESULT DefWindowProcA(
;   [in] HWND   hWnd,
;   [in] UINT   Msg,
;   [in] WPARAM wParam,
;   [in] LPARAM lParam
; );
extern DefWindowProcA    : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-messageboxa
; int MessageBoxA(
;   [in, optional] HWND   hWnd,
;   [in, optional] LPCSTR lpText,
;   [in, optional] LPCSTR lpCaption,
;   [in]           UINT   uType
; );
extern MessageBoxA       : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow
; BOOL ShowWindow(
;   [in] HWND hWnd,
;   [in] int  nCmdShow
; );
extern ShowWindow        : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-updatewindow
; BOOL UpdateWindow(
;   [in] HWND hWnd
; );
extern UpdateWindow      : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowlonga
; LONG SetWindowLongA(
;   [in] HWND hWnd,
;   [in] int  nIndex,
;   [in] LONG dwNewLong
; );
extern SetWindowLongA    : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowpos
; BOOL SetWindowPos(
;   [in]           HWND hWnd,
;   [in, optional] HWND hWndInsertAfter,
;   [in]           int  X,
;   [in]           int  Y,
;   [in]           int  cx,
;   [in]           int  cy,
;   [in]           UINT uFlags
; );
extern SetWindowPos      : proto

; https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-getmodulehandlea
; HMODULE GetModuleHandleA(
;   [in, optional] LPCSTR lpModuleName
; );
extern GetModuleHandleA  : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmonitorinfoa
; BOOL GetMonitorInfoA(
;   [in]  HMONITOR      hMonitor,
;   [out] LPMONITORINFO lpmi
; );
extern GetMonitorInfoA   : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-monitorfromwindow
; HMONITOR MonitorFromWindow(
;   [in] HWND  hwnd,
;   [in] DWORD dwFlags
; );
extern MonitorFromWindow : proto

; https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-stretchdibits
; int StretchDIBits(
;   [in] HDC              hdc,
;   [in] int              xDest,
;   [in] int              yDest,
;   [in] int              DestWidth,
;   [in] int              DestHeight,
;   [in] int              xSrc,
;   [in] int              ySrc,
;   [in] int              SrcWidth,
;   [in] int              SrcHeight,
;   [in] const VOID       *lpBits,
;   [in] const BITMAPINFO *lpbmi,
;   [in] UINT             iUsage,
;   [in] DWORD            rop
; );
extern StretchDIBits     : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getdc
; HDC GetDC(
;   [in] HWND hWnd
; );
extern GetDC             : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-releasedc
; int ReleaseDC(
;   [in] HWND hWnd,
;   [in] HDC  hDC
; );
extern ReleaseDC         : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-beginpaint
; HDC BeginPaint(
;   [in]  HWND          hWnd,
;   [out] LPPAINTSTRUCT lpPaint
; );
extern BeginPaint        : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-endpaint
; BOOL EndPaint(
;   [in] HWND              hWnd,
;   [in] const PAINTSTRUCT *lpPaint
; );
extern EndPaint          : proto

; https://learn.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-getlasterror
; _Post_equals_last_error_ DWORD GetLastError();
extern GetLastError      : proto


; constants

MSVC_SHADOW_SIZE = 20h

; Application-defined resource (raw data). (https://learn.microsoft.com/en-us/windows/win32/menurc/resource-types)
RT_RCDATA = 10

CS_HREDRAW = 02h
CS_VREDRAW = 01h
CS_OWNDC   = 20h

WS_BORDER	        = 00800000h
WS_CAPTION	        = 00c00000h
WS_CHILD	        = 40000000h
WS_CHILDWINDOW	    = 40000000h
WS_CLIPCHILDREN	    = 02000000h
WS_CLIPSIBLINGS	    = 04000000h
WS_DISABLED	        = 08000000h
WS_DLGFRAME	        = 00400000h
WS_GROUP	        = 00020000h
WS_HSCROLL	        = 00100000h
WS_ICONIC	        = 20000000h
WS_MAXIMIZE	        = 01000000h
WS_MAXIMIZEBOX	    = 00010000h
WS_MINIMIZE	        = 20000000h
WS_MINIMIZEBOX	    = 00020000h
WS_OVERLAPPED	    = 00000000h
WS_OVERLAPPEDWINDOW	= (WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_THICKFRAME or WS_MINIMIZEBOX or WS_MAXIMIZEBOX)
WS_POPUP	        = 80000000h
WS_POPUPWINDOW	    = (WS_POPUP or WS_BORDER or WS_SYSMENU)
WS_SIZEBOX	        = 00040000h
WS_SYSMENU	        = 00080000h
WS_TABSTOP	        = 00010000h
WS_THICKFRAME	    = 00040000h
WS_TILED	        = 00000000h
WS_TILEDWINDOW	    = (WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_THICKFRAME or WS_MINIMIZEBOX or WS_MAXIMIZEBOX)
WS_VISIBLE	        = 10000000h
WS_VSCROLL	        = 00200000h

WM_CLOSE = 0010h
WM_QUIT  = 0012h
WM_KEYUP = 0101h

VK_ESCAPE = 1bh

CW_USEDEFAULT = 80000000h

PM_REMOVE = 1

SW_MAXIMIZE = 3

MONITOR_DEFAULTTOPRIMARY = 1

GWL_STYLE = -16

HWND_TOP = 0

SWP_FRAMECHANGED  = 0020h ; The frame changed: send WM_NCCALCSIZE
SWP_NOOWNERZORDER = 0200h ; Don't do owner Z ordering


; structs

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-wndclassa
WNDCLASS struct
    style           dd ?
                    dd ?
    lpfn_wnd_proc   dq ?
    cb_cls_extra    dd ?
    cb_wnd_extra    dd ?
    h_instance      dq ?
    h_icon          dq ?
    h_cursor        dq ?
    hbr_bg          dq ?
    lpsz_menu_name  dq ?
    lpsz_class_name dq ?
WNDCLASS ends

; https://learn.microsoft.com/en-us/windows/win32/api/windef/ns-windef-point
POINT struct
    x dd ?
    y dd ?
POINT ends

; https://learn.microsoft.com/en-us/windows/win32/api/windef/ns-windef-rect
RECT struct
    left   dd ?
    top    dd ?
    right  dd ?
    bottom dd ?
RECT ends

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-msg
MSG struct
    h_wnd     dq    ?
    message   dd    ?
              dd    ?
    w_param   dq    ?
    l_param   dq    ?
    time      dd    ?
    pt        POINT <?>
    l_private dd    ?
MSG ends

; https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-monitorinfo
MONITORINFO struct
    cb_size    dd   ?
    rc_monitor RECT <?>
    rc_work    RECT <?>
    dw_flags   dd   ?
MONITORINFO ends

PAINTSTRUCT struct
    hdc dq ?
    f_erase dd ?
    rc_paint RECT <?>
    f_restore dd ?
    f_inc_update dd ?
    rgb_reserved db 32 dup (?)
PAINTSTRUCT ends

callms macro funcname:req
    push rbp
    mov rbp, rsp
    sub rsp, MSVC_SHADOW_SIZE
    call funcname
    add rsp, MSVC_SHADOW_SIZE
    pop rbp
endm

endif
