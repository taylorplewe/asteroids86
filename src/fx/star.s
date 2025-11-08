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
	mov edx, NUM_STARS / 16

	cmp [is_paused], 0
	jne noMoveLoop

	mov rax, [frame_counter]
	and rax, 1111b
	je moveRightAndDownLoop
	and rax, 111b
	je moveRightLoop

	noMoveLoop:
		call star_draw16
		dec edx
		jne noMoveLoop
	ret

	moveRightLoop:
		; UPDATE (16 at a time)
		vmovdqu ymm0, ymmword ptr [r13]               ; load 16 X word values
		vpaddw ymm0, ymm0, [one_w_256]                ; inc X
		vpcmpgtw ymm2, ymm0, [screen_width_mi1_w_256] ; cmp > screen boundaries
		vpandn ymm0, ymm2, ymm0                       ; zero the ones that were out of bounds
		vmovdqu ymmword ptr [r13], ymm0               ; store new X word values back into memory

		; DRAW (8 at a time) (2 iterations)
		call star_draw16

		dec edx
		jne moveRightLoop
	ret

	moveRightAndDownLoop:
		; UPDATE (16 at a time)
		vmovdqu ymm0, ymmword ptr [r13]                ; load 16 X and Y word values
		vmovdqu ymm1, ymmword ptr [r14]
		vpaddw ymm0, ymm0, [one_w_256]                 ; inc both X and Y
		vpaddw ymm1, ymm1, [one_w_256]
		vpcmpgtw ymm2, ymm0, [screen_width_mi1_w_256]  ; cmp > screen boundaries
		vpcmpgtw ymm3, ymm1, [screen_height_mi1_w_256]
		vpandn ymm0, ymm2, ymm0                        ; zero the ones that were out of bounds
		vpandn ymm1, ymm3, ymm1
		vmovdqu ymmword ptr [r13], ymm0                ; store new X and Y word values back into memory
		vmovdqu ymmword ptr [r14], ymm1

		; DRAW (8 at a time) (2 iterations)
		call star_draw16
		
		dec edx
		jne moveRightAndDownLoop
	ret
star_updateAndDrawAll endp

; in:
	; r13 - pointer to X word values
	; r14 - pointer to Y word values
	; r15 - pointer to alpha byte values
star_draw16 proc
	; 8 LOWER words, followed by 8 UPPER words
	repeat 2
		; convert words to dwords
		vmovdqu xmm0, xmmword ptr [r13]
		vmovdqu xmm1, xmmword ptr [r14]
		vpmovzxwd ymm2, xmm0
		vpmovzxwd ymm3, xmm1
		; get color alphas for 8 stars
		vmovq xmm4, qword ptr [r15]
		vpmovzxbd ymm4, xmm4
		vpslld ymm4, ymm4, 24
		vpor ymm4, ymm4, ymmword ptr [opaque_pixel_no_alpha_d_256]

		call screen_setPixelOnscreenVerifiedSimd

		add r13, 16
		add r14, 16
		add r15, 8
	endm
	ret
star_draw16 endp


endif
