SCREEN_WIDTH  = 1920/2
SCREEN_HEIGHT = 1200/2

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
