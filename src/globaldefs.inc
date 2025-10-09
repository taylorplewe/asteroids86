SCREEN_WIDTH  = 1100
SCREEN_HEIGHT = 800

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
	mov ebx, eax
	sar ebx, 31 ; 00000000h or 0ffffffffh
	xor eax, ebx
	sub eax, ebx
endm
