%ifndef star_h
%define star_h

%include "src/global.asm"


struc Star
	.pos:       resb Point16_size
	.luminence: resb      1
	            resb      1
			    resb      1
			    resb      1
endstruc

NUM_STARS equ 1000


section .bss

stars: resb Star_size * NUM_STARS


section .text

; top-level
star_generateAll:
	lea rdi, stars
	mov ecx, NUM_STARS
	.loop:
		; x
		mov r8w, SCREEN_WIDTH
		rand ax
		and ax, 7fffh
		cwd
		div r8w
		mov [rdi + Star.pos + Point.x], dx

		; y
		mov r8w, SCREEN_HEIGHT
		rand ax
		and ax, 7fffh
		cwd
		div r8w
		mov [rdi + Star.pos + Point.y], dx

		; luminence
		rand ax
		and al, 7fh
		mov [rdi + Star.luminence], al

		add rdi, Star_size
		loop .loop
	ret


star_updateAndDrawAll:
	lea rdi, pixels
	lea rsi, stars
	mov r8d, [fg_color]
	xor ebx, ebx
	xor ecx, ecx
	mov edx, NUM_STARS

	%macro star_updateAndDrawAll_drawStar 0
		mov bx, [rsi + Star.pos + Point.x]
		mov cx, [rsi + Star.pos + Point.y]
		and r8d, 00ffffffh
		or r8d, dword [rsi + 3 + Star.luminence] ; this puts the luminence byte in the upper 8 bits of eax

		; in:
			; ebx  - x
			; ecx  - y
			; r8d  - color
			; rdi  - point to pixels
		call screen_setPixelOnscreenVerified
	%endmacro

	%macro star_updateAndDrawAll_loopCmp 1 ;jmpLabel:req
		add rsi, Star_size
		dec edx
		jne %1
	%endmacro

	cmp [is_paused], 0
	jne .noMoveLoop

	mov rax, [frame_counter]
	and rax, 1111b
	je .moveRightAndDownLoop
	and rax, 111b
	je .moveRightLoop

	.noMoveLoop:
		star_updateAndDrawAll_drawStar
		star_updateAndDrawAll_loopCmp .noMoveLoop
	ret

	.moveRightLoop:
		star_updateAndDrawAll_drawStar

		inc dword [rsi + Star.pos + Point.x]
		cmp dword [rsi + Star.pos + Point.x], SCREEN_WIDTH
		jl ._
			mov dword [rsi + Star.pos + Point.x], 0
		._:

		star_updateAndDrawAll_loopCmp .moveRightLoop
	ret

	.moveRightAndDownLoop:
		star_updateAndDrawAll_drawStar

		inc dword [rsi + Star.pos + Point.x]
		cmp dword [rsi + Star.pos + Point.x], SCREEN_WIDTH
		jl ._1
			mov dword [rsi + Star.pos + Point.x], 0
		._1:

		inc dword [rsi + Star.pos + Point.y]
		cmp dword [rsi + Star.pos + Point.y], SCREEN_HEIGHT
		jl ._2
			mov dword [rsi + Star.pos + Point.y], 0
		._2:

		star_updateAndDrawAll_loopCmp .moveRightAndDownLoop
	ret



%endif
