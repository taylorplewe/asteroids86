extern ExitProcess   : proto

; https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-findresourcea
; HRSRC FindResourceA(
;   [in, optional] HMODULE hModule,
;   [in]           LPCSTR  lpName,
;   [in]           LPCSTR  lpType
; );
extern FindResourceA : proto :ptr, :ptr, :ptr

; https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-loadresource
; HGLOBAL LoadResource(
;   [in, optional] HMODULE hModule,
;   [in]           HRSRC   hResInfo
; );
extern LoadResource : proto :ptr, :ptr

; https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-lockresource
; LPVOID LockResource(
;   [in] HGLOBAL hResData
; );
extern LockResource : proto :ptr

; Application-defined resource (raw data). (https://learn.microsoft.com/en-us/windows/win32/menurc/resource-types)
RT_RCDATA = 10
