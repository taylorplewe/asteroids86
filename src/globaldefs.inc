%ifndef globaldefs_h
%define globaldefs_h


; SCREEN_WIDTH  equ 1920
; SCREEN_HEIGHT equ 1080

; SCREEN_WIDTH  equ 1600
; SCREEN_HEIGHT equ 900

; SCREEN_WIDTH  equ 1440
; SCREEN_HEIGHT equ 810

SCREEN_WIDTH  equ 1280
SCREEN_HEIGHT equ 720

DIM_ALPHA equ 20h


%define Mode dd
Title equ 0
Game  equ 1

struc FatPtr
	pntr: qword ?
	len:  dd    ?
endstruc

struc Pixel
	r: resb 1
	g: resb 1
	b: resb 1
	a: resb 1
endstruc

struc Point
	x dd ?
	y dd ?
endstruc
struc Point16
	x dw ?
	y dw ?
endstruc
Vector typedef Point ; ??
struc Dim
	w dd ?
	h dd ?
endstruc
struc Rect
	pos Point <>
	dim Dim   <>
endstruc

; rotations and line lengths for drawing things
struc BasePoint
	vec dd ?
	rad db ? ; 256-based radians; 256 = 360 degrees
endstruc

%define Keys dd
Keys_Boost    equ 0
Keys_Teleport equ 1
Keys_Left     equ 2
Keys_Right    equ 3
Keys_Fire     equ 4
Keys_Quit     equ 5
Keys_Pause    equ 6
Keys_Other    equ 7 ; for detecting if any key was pressed

struc Input
	buttons_down     Keys ?
	buttons_pressed  Keys ?
	buttons_released Keys ?
endstruc

enum Event
%define Event dd
Event_Fire        equ 0
Event_ShipDestroy equ 1

abseax macro
	push rbx
	mov ebx, eax
	sar ebx, 31 ; 00000000h or 0ffffffffh
	xor eax, ebx
	sub eax, ebx
	pop rbx
endm

saturatingSub32 macro reg:req, val:req
	sub reg, val
	cmovs reg, dword ptr [zero64]
endm

brk macro
	int 3
endm

rand macro reg:req
	local randCheck
	randCheck:
	rdrand reg
	jnc randCheck ; random value ready? (https://www.felixcloutier.com/x86/rdrand#description)
endm


%endif
