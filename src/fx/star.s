%ifndef star_h
%define star_h

%include "global.s"


struc Star
	pos       Point16 <>
	luminence db      ?
	          db      ?
			  db      ?
			  db      ?
endstruc

NUM_STARS = 1000


.data?

stars Star NUM_STARS dup (<>)


.code

; top-level
star_generateAll proc
	lea rdi, stars
	mov ecx, NUM_STARS
	_loop:
		; x
		mov r8w, SCREEN_WIDTH
		rand ax
		and ax, 7fffh
		cwd
		div r8w
		mov [rdi].Star.pos.x, dx

		; y
		mov r8w, SCREEN_HEIGHT
		rand ax
		and ax, 7fffh
		cwd
		div r8w
		mov [rdi].Star.pos.y, dx

		; luminence
		rand ax
		and al, 7fh
		mov [rdi].Star.luminence, al

		add rdi, sizeof Star
		loop _loop
	ret
star_generateAll endp

star_updateAndDrawAll proc
	lea rdi, pixels
	lea rsi, stars
	mov r8d, [fg_color]
	xor ebx, ebx
	xor ecx, ecx
	mov edx, NUM_STARS

	star_updateAndDrawAll_drawStar macro
		mov bx, [rsi].Star.pos.x
		mov cx, [rsi].Star.pos.y
		and r8d, 00ffffffh
		or r8d, dword ptr [rsi + 3].Star.luminence ; this puts the luminence byte in the upper 8 bits of eax

		; in:
			; ebx  - x
			; ecx  - y
			; r8d  - color
			; rdi  - point to pixels
		call screen_setPixelOnscreenVerified
	endm

	star_updateAndDrawAll_loopCmp macro jmpLabel:req
		add rsi, sizeof Star
		dec edx
		jne jmpLabel
	endm

	cmp [is_paused], 0
	jne noMoveLoop

	mov rax, [frame_counter]
	and rax, 1111b
	je moveRightAndDownLoop
	and rax, 111b
	je moveRightLoop

	noMoveLoop:
		star_updateAndDrawAll_drawStar
		star_updateAndDrawAll_loopCmp noMoveLoop
	ret

	moveRightLoop:
		star_updateAndDrawAll_drawStar

		inc [rsi].Star.pos.x
		cmp [rsi].Star.pos.x, SCREEN_WIDTH
		jl @f
			mov [rsi].Star.pos.x, 0
		@@:

		star_updateAndDrawAll_loopCmp moveRightLoop
	ret

	moveRightAndDownLoop:
		star_updateAndDrawAll_drawStar

		inc [rsi].Star.pos.x
		cmp [rsi].Star.pos.x, SCREEN_WIDTH
		jl @f
			mov [rsi].Star.pos.x, 0
		@@:

		inc [rsi].Star.pos.y
		cmp [rsi].Star.pos.y, SCREEN_HEIGHT
		jl @f
			mov [rsi].Star.pos.y, 0
		@@:

		star_updateAndDrawAll_loopCmp moveRightAndDownLoop
	ret
star_updateAndDrawAll endp


%endif
