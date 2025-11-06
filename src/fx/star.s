ifndef star_h
star_h = 1

include <global.s>


NUM_STARS = 1024
; struct of arrays
Stars struct
	x         dw NUM_STARS dup (?)
	y         dw NUM_STARS dup (?)
	luminence db NUM_STARS dup (?)
Stars ends


.data

; could also just use one word for each and broadcast them into a ymm register
one_w_256           dw (256 / 2) dup (1)
screen_width_w_256  dw (256 / 2) dup (SCREEN_WIDTH)
screen_height_w_256 dw (256 / 2) dup (SCREEN_HEIGHT)


.data?

stars Stars <>


.code

; top-level
star_generateAll proc
	lea r13, stars + Stars.x
	lea r14, stars + Stars.y
	lea r15, stars + Stars.luminence
	mov ecx, NUM_STARS
	_loop:
		; x
		mov r8w, SCREEN_WIDTH
		rand ax
		and ax, 7fffh
		cwd
		div r8w
		mov word ptr [r13], dx

		; y
		mov r8w, SCREEN_HEIGHT
		rand ax
		and ax, 7fffh
		cwd
		div r8w
		mov word ptr [r14], dx

		; luminence
		rand ax
		mov byte ptr [r15], al

		add r13, 2
		add r14, 2
		inc r15
		loop _loop
	ret
star_generateAll endp

star_updateAndDrawAll proc
	lea r13, stars + Stars.x
	lea r14, stars + Stars.y
	lea r15, stars + Stars.luminence

	lea rdi, pixels
	mov r8d, [fg_color]
	xor ebx, ebx
	xor ecx, ecx
	mov edx, NUM_STARS

	star_updateAndDrawAll_drawStar macro
		mov bx, word ptr [r13]
		mov cx, word ptr [r14]
		and r8d, 00ffffffh
		mov al, byte ptr [r15]
		shl eax, 24
		or r8d, eax

		; in:
			; ebx  - x
			; ecx  - y
			; r8d  - color
			; rdi  - point to pixels
		call screen_setPixelOnscreenVerified
	endm

	star_updateAndDrawAll_loopCmp macro jmpLabel:req
		inc r13
		inc r13
		inc r14
		inc r14
		inc r15
		dec edx
		jne jmpLabel
	endm

	cmp [is_paused], 0
	jne noMoveLoop

	mov rax, [frame_counter]
	and rax, 1111b
	je moveRightAndDownLoopBefore
	and rax, 111b
	je moveRightLoop

	noMoveLoop:
		star_updateAndDrawAll_drawStar
		star_updateAndDrawAll_loopCmp noMoveLoop
	ret

	moveRightLoop:
		star_updateAndDrawAll_drawStar

		inc word ptr [r13]
		cmp word ptr [r13], SCREEN_WIDTH
		jl @f
			mov word ptr [r13], 0
		@@:

		star_updateAndDrawAll_loopCmp moveRightLoop
	ret

	moveRightAndDownLoopBefore:
	rdtsc
	mov r10d, edx
	shl r10, 32
	or r10, rax
	mov edx, NUM_STARS
	moveRightAndDownLoop:
		star_updateAndDrawAll_drawStar

		vmovdqu16 ymm0, [r13]
		vmovdqu16 ymm1, [r14]

		vpaddw ymm0, ymm0, [one_w_256]
		vpaddw ymm1, ymm1, [one_w_256]

		vpcmpgtw ymm2, ymm0, [screen_width_w_256]
		vpcmpgtw ymm3, ymm1, [screen_height_w_256]

		vpandn ymm0, ymm2, ymm0
		vpandn ymm1, ymm3, ymm1

		vmovdqu16 [r13], ymm0
		vmovdqu16 [r14], ymm1

		; inc word ptr [r13]
		; cmp word ptr [r13], SCREEN_WIDTH
		; jl @f
		; 	mov word ptr [r13], 0
		; @@:

		; inc word ptr [r14]
		; cmp word ptr [r14], SCREEN_HEIGHT
		; jl @f
		; 	mov word ptr [r14], 0
		; @@:

		star_updateAndDrawAll_loopCmp moveRightAndDownLoop
	rdtsc
	shl rdx, 32
	or rdx, rax
	sub rdx, r10
	; brk
	; read RDX
	ret
star_updateAndDrawAll endp


endif
