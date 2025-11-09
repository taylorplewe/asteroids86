%ifndef star_h
%define star_h

%include "src/global.asm"


NUM_STARS equ 1024
; struct of arrays
struc Stars
	.x         resw NUM_STARS
	.y         resw NUM_STARS
	.luminence resb NUM_STARS
endstruc


section .data

; could also just use one word for each and broadcast them into a ymm register
one_w_256                   dw (256 / 2) dup (1)
screen_width_mi1_w_256      dw (256 / 2) dup (SCREEN_WIDTH - 1) ; minus one makes the comparison much easier since it can only do > and not >=
screen_height_mi1_w_256     dw (256 / 2) dup (SCREEN_HEIGHT - 1)
opaque_pixel_no_alpha_d_256 dd (256 / 4) dup (00ffffffh)


section .bss

stars resb Stars_size


section .text

; top-level
star_generateAll:
	lea r13, stars + Stars.x
	lea r14, stars + Stars.y
	lea r15, stars + Stars.luminence
	mov ecx, NUM_STARS
	.loop:
		; x
		mov r8w, SCREEN_WIDTH
		rand ax
		and ax, 7fffh
		cwd
		div r8w
		mov word [r13], dx

		; y
		mov r8w, SCREEN_HEIGHT
		rand ax
		and ax, 7fffh
		cwd
		div r8w
		mov word [r14], dx

		; luminence
		rand ax
		mov byte [r15], al

		add r13, 2
		add r14, 2
		inc r15
		loop .loop
	ret

star_drawAll:
	lea r13, stars + Stars.x
	lea r14, stars + Stars.y
	lea r15, stars + Stars.luminence

	; lea rdi, pixels
	mov rdi, [pixels]
	mov r8d, [fg_color]
	xor ebx, ebx
	xor ecx, ecx
	mov edx, NUM_STARS / 16

	cmp dword [is_paused], 0
	jne .noMoveLoop

	mov rax, [frame_counter]
	and rax, 1111b
	je .moveRightAndDownLoop
	and rax, 111b
	je .moveRightLoop

	.noMoveLoop:
		call star_draw16
		dec edx
		jne .noMoveLoop
	ret

	.moveRightLoop:
		; UPDATE (16 at a time)
		vmovdqu ymm0, yword [r13]               ; load 16 X word values
		vpaddw ymm0, ymm0, [one_w_256]                ; inc X
		vpcmpgtw ymm2, ymm0, [screen_width_mi1_w_256] ; cmp > screen boundaries
		vpandn ymm0, ymm2, ymm0                       ; zero the ones that were out of bounds
		vmovdqu yword [r13], ymm0               ; store new X word values back into memory

		; DRAW (8 at a time) (2 iterations)
		call star_draw16

		dec edx
		jne .moveRightLoop
	ret

	.moveRightAndDownLoop:
		; UPDATE (16 at a time)
		vmovdqu ymm0, yword [r13]                ; load 16 X and Y word values
		vmovdqu ymm1, yword [r14]
		vpaddw ymm0, ymm0, [one_w_256]                 ; inc both X and Y
		vpaddw ymm1, ymm1, [one_w_256]
		vpcmpgtw ymm2, ymm0, [screen_width_mi1_w_256]  ; cmp > screen boundaries
		vpcmpgtw ymm3, ymm1, [screen_height_mi1_w_256]
		vpandn ymm0, ymm2, ymm0                        ; zero the ones that were out of bounds
		vpandn ymm1, ymm3, ymm1
		vmovdqu yword [r13], ymm0                ; store new X and Y word values back into memory
		vmovdqu yword [r14], ymm1

		; DRAW (8 at a time) (2 iterations)
		call star_draw16
		
		dec edx
		jne .moveRightAndDownLoop
	ret

; in:
	; r13 - pointer to X word values
	; r14 - pointer to Y word values
	; r15 - pointer to alpha byte values
star_draw16:
	lea rdi, pixels
	; 8 LOWER words, followed by 8 UPPER words
	%rep 2
		; convert words to dwords
		vmovdqu xmm0, oword [r13]
		vmovdqu xmm1, oword [r14]
		vpmovzxwd ymm2, xmm0
		vpmovzxwd ymm3, xmm1
		; get color alphas for 8 stars
		vmovq xmm4, qword [r15]
		vpmovzxbd ymm4, xmm4
		vpslld ymm4, ymm4, 24
		vpor ymm4, ymm4, yword [opaque_pixel_no_alpha_d_256]

		call screen_setPixelOnscreenVerifiedSimd

		add r13, 16
		add r14, 16
		add r15, 8
	%endrep
	ret


%endif