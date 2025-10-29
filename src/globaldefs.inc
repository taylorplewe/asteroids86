ifndef globaldefs_h
globaldefs_h = 1


; SCREEN_WIDTH  = 1920
; SCREEN_HEIGHT = 1080

; SCREEN_WIDTH  = 1600
; SCREEN_HEIGHT = 900

; SCREEN_WIDTH  = 1440
; SCREEN_HEIGHT = 810

SCREEN_WIDTH  = 1280
SCREEN_HEIGHT = 720

DIM_ALPHA = 20h

FatPtr struct
	pntr qword ?
	len  dd    ?
FatPtr ends

Pixel struct
	r db ?
	g db ?
	b db ?
	a db ?
Pixel ends

Point struct
	x dd ?
	y dd ?
Point ends
Vector typedef Point ; ??
Dim struct
	w dd ?
	h dd ?
Dim ends
Rect struct
	pos Point <>
	dim Dim   <>
Rect ends

; rotations and line lengths for drawing things
BasePoint struct
	vec dd ?
	rad db ? ; 256-based radians; 256 = 360 degrees
BasePoint ends

Keys struct
	up    db ?
	down  db ?
	left  db ?
	right db ?
	fire  db ?
	quit  db ?
	menu  db ?
Keys ends

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


endif
