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
	.pntr: resq 1
	.len:  resd 1
endstruc

struc Pixel
	.r: resb 1
	.g: resb 1
	.b: resb 1
	.a: resb 1
endstruc

struc Point
	.x: resd 1
	.y: resd 1
endstruc
struc Point16
	.x: resw 1
	.y: resw 1
endstruc
%define Vector Point
struc Dim
	.w: resd 1
	.h: resd 1
endstruc
struc Rect
	.pos: resb Point_size
	.dim: resb Dim_size
endstruc

; rotations and line lengths for drawing things
struc BasePoint
	.vec: resd 1
	.rad: resb 1 ; 256-based radians; 256 = 360 degrees
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
	.buttons_down:     Keys 1
	.buttons_pressed:  Keys 1
	.buttons_released: Keys 1
endstruc

%define Event dd
Event_Fire        equ 0
Event_ShipDestroy equ 1

%macro abseax 0
	push rbx
	mov ebx, eax
	sar ebx, 31 ; 00000000h or 0ffffffffh
	xor eax, ebx
	sub eax, ebx
	pop rbx
%endmacro

%macro saturatingSub32 2 ;reg:req, val:req
	sub %1, %2
	cmovs %1, dword [zero64]
%endmacro

%macro brk 0
	int 3
%endmacro

%macro rand 1 ;reg:req
	%%randCheck:
	rdrand %1
	jnc %%randCheck ; random value ready? (https://www.felixcloutier.com/x86/rdrand#description)
%endmacro


%endif
