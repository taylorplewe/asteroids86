ifndef title_h
title_h = 1

include <globaldefs.inc>
include <data\title-points.inc>

include <global.s>
include <screen.s>


TITLE_NUM_FRAMES                   = 3
TITLE_FRAME_TIME                   = 12
TITLE_86_FLICKER_DELAY_COUNTER_AMT = 60 * 2


.data?

title_point1                   Point <>
title_point2                   Point <>
title_anim_frame               dd    ?
title_anim_counter             dd    ?
title_86_flicker_delay_counter dd    ?
title_86_flicker_inds          dd    2 dup (?)


.code

title_init proc
	mov [title_86_flicker_delay_counter], TITLE_86_FLICKER_DELAY_COUNTER_AMT

	ret
title_init endp

title_tick proc
	call title_drawAsteroids
	call title_draw86

	; advance ASTEROIDS animation
	inc [title_anim_counter]
	cmp [title_anim_counter], TITLE_FRAME_TIME
	jl @f
	jne @f
		mov [title_anim_counter], 0
		inc [title_anim_frame]
		cmp [title_anim_frame], 3
		jl @f
		mov [title_anim_frame], 0
	@@:

	; advance 86 flicker
	cmp [title_86_flicker_inds], 0
	je @f
		i = 0
		repeat 2
			local next
			cmp [title_86_flicker_inds + i * 4], flicker_alphas_len
			jge next
			inc [title_86_flicker_inds + i * 4]

			next:
			i = i + 1
		endm
	@@:

	; count down 86 appear delay
	cmp [title_86_flicker_delay_counter], 0
	je _86FlickerDelayEnd
		dec [title_86_flicker_delay_counter]
		jne _86FlickerDelayEnd
		; generate 2 random indexes into the flicker array
		i = 0
		repeat 2
			rand eax
			and eax, 11111b
			inc eax
			mov [title_86_flicker_inds + i * 4], eax
			i = i + 1
		endm

	_86FlickerDelayEnd:

	ret
title_tick endp

; in:
	; ebx - index
title_drawLine proc
	xor eax, eax
	mov ax, [rsi]
	mov [screen_point1].x, eax
	mov ax, [rsi + 2]
	mov [screen_point1].y, eax
	mov ax, [rsi + 4]
	mov [screen_point2].x, eax
	mov ax, [rsi + 6]
	mov [screen_point2].y, eax
	call screen_drawLine
	ret
title_drawLine endp

title_drawAsteroids proc
	lea rsi, title_points_tab
	mov eax, [title_anim_frame]
	shl eax, 3
	mov rsi, [rsi + rax]
	mov r8d, [fg_color]

	push rsi
	for ind, <4, 8, 8, 4, 4, 4, 4, 8, 8, 8, 4, 4, 8, 8, 4, 4, 4, 8, 8, 4, 4, 8, 8, 4, 4, 8, 4, 4, 4, 4, 0>
		call title_drawLine
		add rsi, ind
	endm
	pop rsi

	; close the O
	xor eax, eax
	mov ax, [rsi + 124]
	mov [screen_point1].x, eax
	mov ax, [rsi + 126]
	mov [screen_point1].y, eax
	mov ax, [rsi + 112]
	mov [screen_point2].x, eax
	mov ax, [rsi + 114]
	mov [screen_point2].y, eax
	call screen_drawLine

	; close the D
	xor eax, eax
	mov ax, [rsi + 148]
	mov [screen_point1].x, eax
	mov ax, [rsi + 150]
	mov [screen_point1].y, eax
	mov ax, [rsi + 136]
	mov [screen_point2].x, eax
	mov ax, [rsi + 138]
	mov [screen_point2].y, eax
	call screen_drawLine

	ret
title_drawAsteroids endp

title_draw86 proc
	cmp [title_86_flicker_inds], 0
	je _ret

	push rdx
	push rsi
	push rdi
	push r8
	push r9
	push r14

	lea rdx, font_current_char_pos
	mov rsi, [font_digits_spr_data]
	mov r8d, [fg_color]
	lea r9, font_current_char_rect
	lea r14, screen_setPixelOnscreenVerified

	mov [font_current_char_pos].x, 1010 shl 16
	mov [font_current_char_pos].y, 428 shl 16
	mov [font_current_char_rect].pos.x, 8 * FONT_DIGIT_WIDTH
	mov [font_current_char_rect].pos.y, 0
	mov [font_current_char_rect].dim.w, FONT_DIGIT_WIDTH
	mov [font_current_char_rect].dim.h, FONT_DIGIT_HEIGHT

	; flicker alpha
	and r8d, 00ffffffh
	mov eax, [title_86_flicker_inds]
	lea rdi, flicker_alphas
	mov edi, [rdi + rax]
	mov eax, 0ffh
	sub eax, edi
	shl eax, 24
	or r8d, eax

	call screen_draw1bppSprite

	add [font_current_char_pos].x, (FONT_DIGIT_WIDTH + 5) shl 16
	mov [font_current_char_rect].pos.x, 6 * FONT_DIGIT_WIDTH

	; flicker alpha
	and r8d, 00ffffffh
	mov eax, [title_86_flicker_inds + 4]
	lea rdi, flicker_alphas
	mov edi, [rdi + rax]
	mov eax, 0ffh
	sub eax, edi
	shl eax, 24
	or r8d, eax

	call screen_draw1bppSprite

	pop r14
	pop r9
	pop r8
	pop rdi
	pop rsi
	pop rdx
	_ret:
	ret
title_draw86 endp


endif
