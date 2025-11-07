ifndef star_h
star_h = 1

include <global.s>


NUM_STARS = 1024
; struct of arrays
Stars struct 16
	x         dw NUM_STARS dup (?)
	y         dw NUM_STARS dup (?)
	luminence db NUM_STARS dup (?)
Stars ends


.data

; could also just use one word for each and broadcast them into a ymm register
one_w_256                   dw (256 / 2) dup (1)
screen_width_mi1_w_256      dw (256 / 2) dup (SCREEN_WIDTH - 1) ; minus one makes the comparison much easier since it can only do > and not >=
screen_height_mi1_w_256     dw (256 / 2) dup (SCREEN_HEIGHT - 1)
opaque_pixel_no_alpha_d_256 dd (256 / 4) dup (00ffffffh)


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
	; brk
	rdtsc
	mov r10d, edx
	shl r10, 32
	or r10, rax
	mov edx, NUM_STARS / 16
	moveRightAndDownLoop:
		; UPDATE (16 at a time)

		; load 16 X and Y word values
		vmovdqu ymm0, ymmword ptr [r13]
		vmovdqu ymm1, ymmword ptr [r14]

		; inc both X and Y
		vpaddw ymm0, ymm0, [one_w_256]
		vpaddw ymm1, ymm1, [one_w_256]

		; cmp > screen boundaries
		vpcmpgtw ymm2, ymm0, [screen_width_mi1_w_256]
		vpcmpgtw ymm3, ymm1, [screen_height_mi1_w_256]

		; zero the ones that were out of bounds
		vpandn ymm0, ymm2, ymm0
		vpandn ymm1, ymm3, ymm1

		; store new X and Y word values back into memory
		vmovdqu ymmword ptr [r13], ymm0
		vmovdqu ymmword ptr [r14], ymm1

		; DRAW (8 at a time) (2 iterations)

		; 8 LOWER words
		vpmovzxwd ymm2, xmm0
		vpmovzxwd ymm3, xmm1
		; get colors for 8 stars
		vmovq xmm4, qword ptr [r15]
		vpmovzxbd ymm4, xmm4
		vpslld ymm4, ymm4, 24
		vpor ymm4, ymm4, ymmword ptr [opaque_pixel_no_alpha_d_256]

		call screen_setPixelOnscreenVerifiedSimd

		add r13, 16
		add r14, 16
		add r15, 8

		; 8 UPPER words
		vmovdqu xmm0, xmmword ptr [r13]
		vmovdqu xmm1, xmmword ptr [r14]
		vpmovzxwd ymm2, xmm0
		vpmovzxwd ymm3, xmm1
		; get colors for 8 stars
		vmovq xmm4, qword ptr [r15]
		vpmovzxbd ymm4, xmm4
		vpslld ymm4, ymm4, 24
		vpor ymm4, ymm4, ymmword ptr [opaque_pixel_no_alpha_d_256]

		call screen_setPixelOnscreenVerifiedSimd

		add r13, 16
		add r14, 16
		add r15, 8

		dec edx
		jne moveRightAndDownLoop
	rdtsc
	shl rdx, 32
	or rdx, rax
	sub rdx, r10
	brk
	ret
star_updateAndDrawAll endp


endif
