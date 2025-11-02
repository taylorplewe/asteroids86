ifndef title_h
title_h = 1

include <globaldefs.inc>
include <data\title-points.inc>

include <global.s>
include <screen.s>


TITLE_APPEAR_DELAY_COUNTER_AMT     = 60 * 2
TITLE_MAX_NUM_LINES_TO_DRAW        = 33
TITLE_NUM_FRAMES                   = 3
TITLE_FRAME_TIME                   = 12
TITLE_86_FLICKER_DELAY_COUNTER_AMT = 60 * 2
TITLE_PRESS_ANY_KEY_Y              = ((SCREEN_HEIGHT / 2) + (SCREEN_HEIGHT / 4)) shl 16
TITLE_PRESS_ANY_KEY_COUNTER_AMT    = 60 * 4


.data?

title_point1     Point <>
title_point2     Point <>

; animation
title_appear_delay_counter       dd ?
title_num_lines_to_draw          dd ?
title_anim_frame                 dd ?
title_anim_counter               dd ?
title_86_flicker_delay_counter   dd ?
title_86_flicker_inds            dd 2 dup (?)
title_show_press_any_key_counter dd ?


.code

title_init proc
	mov [title_appear_delay_counter], TITLE_APPEAR_DELAY_COUNTER_AMT
	mov [title_num_lines_to_draw], 0
	mov [title_anim_frame], 0
	mov [title_anim_counter], 0
	mov [title_86_flicker_delay_counter], 0
	mov [title_86_flicker_inds], 0
	mov [title_show_press_any_key_counter], 0
	mov [screen_show_press_any_key], 0

	ret
title_init endp

; in:
	; rdi - pointer to Keys struct of keys pressed
title_tick proc
	bt Keys ptr [rdi], Keys_Any
	jnc anyKeyPressEnd
		cmp [screen_show_press_any_key], 0
		je @f
			call game_init
			mov [mode], Mode_Game
			ret
		@@:
			call title_skipAnim
	anyKeyPressEnd:

	call title_drawAsteroids
	call title_draw86
	call title_drawCredit

	; "Press any key to continue"
	cmp [screen_show_press_any_key], 0
	je @f
		mov [font_current_char_pos].y, TITLE_PRESS_ANY_KEY_Y
		call screen_drawPressAnyKey
	@@:

	cmp [title_show_press_any_key_counter], 0
	je @f
		dec [title_show_press_any_key_counter]
		jne @f
		inc [screen_show_press_any_key]
	@@:

	; sweep left to right drawing lines
	mov eax, [title_num_lines_to_draw]
	test eax, eax
	je @f
	cmp eax, TITLE_MAX_NUM_LINES_TO_DRAW
	jge @f
		inc eax
		mov [title_num_lines_to_draw], eax
		cmp eax, TITLE_MAX_NUM_LINES_TO_DRAW
		jl @f
		mov [title_86_flicker_delay_counter], TITLE_86_FLICKER_DELAY_COUNTER_AMT
		mov [title_show_press_any_key_counter], TITLE_PRESS_ANY_KEY_COUNTER_AMT
	@@:

	; appear delay counter
	cmp [title_appear_delay_counter], 0
	je @f
		dec [title_appear_delay_counter]
		jne @f
		inc [title_num_lines_to_draw]
	@@:

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

title_skipAnim proc
	mov [title_appear_delay_counter], 0
	mov [title_86_flicker_delay_counter], 0
	mov [title_show_press_any_key_counter], 0

	mov [title_num_lines_to_draw], TITLE_MAX_NUM_LINES_TO_DRAW
	mov [title_86_flicker_inds], flicker_alphas_len - 1
	mov [title_86_flicker_inds + 4], flicker_alphas_len - 1
	mov [screen_show_press_any_key], 1
	ret
title_skipAnim endp

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
	push rcx
	call screen_drawLine
	pop rcx
	ret
title_drawLine endp

title_drawAsteroids proc
	cmp [title_appear_delay_counter], 0
	jne _ret

	push rcx
	push rsi
	push r8

	lea rsi, title_points_tab
	mov eax, [title_anim_frame]
	shl eax, 3
	mov rsi, [rsi + rax]
	mov r8d, [fg_color]

	mov ecx, [title_num_lines_to_draw]
	for ind, <4, 8, 8, 4, 4, 4, 4, 8, 8, 8, 4, 4, 8, 8, 4, 4, 4, 8, 8, 4, 4, 4, 8, 8, 4, 4, 4, 8, 4, 4, 4, 4, 0>
		call title_drawLine
		add rsi, ind
		dec ecx
		je _end
	endm

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

	_end:
	pop r8
	pop rsi
	pop rcx
	_ret:
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

TITLE_CREDIT_X = ((SCREEN_WIDTH / 2) + 248) shl 16
TITLE_CREDIT_Y = (SCREEN_HEIGHT - 32) shl 16
my_name db "TAYLOR PLEWE"
my_name_len = $ - my_name
title_drawCredit proc
	cmp [screen_show_press_any_key], 0
	je _ret

	push rbx
	push rcx
	push rdx
	push rsi
	push r8
	push r9
	push r10
	push r14

	lea rdx, font_current_char_pos
	lea r9, font_current_char_rect
	mov r8d, [gray_color]
	lea r14, screen_setPixelOnscreenVerified
	mov [font_current_char_pos].x, TITLE_CREDIT_X
	mov [font_current_char_pos].y, TITLE_CREDIT_Y

	; copyright symbol
	mov rsi, [font_copyright_spr_data]
	mov [font_current_char_rect].pos.x, 0
	mov [font_current_char_rect].pos.y, 0
	mov [font_current_char_rect].dim.w, FONT_COPYRIGHT_WIDTH
	mov [font_current_char_rect].dim.h, FONT_COPYRIGHT_HEIGHT
	call screen_draw1bppSprite

	add [font_current_char_pos].x, (PRESS_ANY_KEY_CHAR_WIDTH + 8) shl 16

	; my name
	mov [font_current_char_rect].dim.h, FONT_SM_CHAR_HEIGHT
	lea rbx, my_name
	xor ecx, ecx
	xor r10, r10
	nameLoop:
		xor eax, eax
		mov al, cl
		xlatb ; Table Look-up Translation; al = byte ptr [rbx + al]
		cmp al, ' '
		je nameLoopDrawCharEnd
		cmp al, 'W'
		sete r10b
		je nameLoopW
			sub al, 'A'
			mov rsi, [font_small_spr_data]
			mov [font_current_char_rect].dim.w, FONT_SM_CHAR_WIDTH
			imul eax, FONT_SM_CHAR_WIDTH
			jmp nameLoopCharRectSetEnd
		nameLoopW:
			add [font_current_char_pos].x, (FONT_SM_CHAR_WIDTH / 2) shl 16
			mov rsi, [font_small_w_spr_data]
			mov [font_current_char_rect].dim.w, FONT_SM_W_WIDTH
			mov eax, 0
		nameLoopCharRectSetEnd:
		mov [font_current_char_rect].pos.x, eax

		call screen_draw1bppSprite

		nameLoopDrawCharEnd:
		add [font_current_char_pos].x, PRESS_ANY_KEY_CHAR_WIDTH shl 16
		test r10, r10
		je @f
			add [font_current_char_pos].x, (FONT_SM_CHAR_WIDTH / 2) shl 16
		@@:

		inc ecx
		cmp ecx, my_name_len
		jl nameLoop

	add [font_current_char_pos].x, PRESS_ANY_KEY_CHAR_WIDTH shl 16

	; creation year
	mov rsi, [font_yr_digits_spr_data]
	mov [font_current_char_rect].dim.w, FONT_SM_CHAR_WIDTH
	mov [font_current_char_rect].pos.x, 0
	call screen_draw1bppSprite

	add [font_current_char_pos].x, PRESS_ANY_KEY_CHAR_WIDTH shl 16
	mov [font_current_char_rect].pos.x, FONT_SM_CHAR_WIDTH
	call screen_draw1bppSprite

	add [font_current_char_pos].x, PRESS_ANY_KEY_CHAR_WIDTH shl 16
	mov [font_current_char_rect].pos.x, 0
	call screen_draw1bppSprite

	add [font_current_char_pos].x, PRESS_ANY_KEY_CHAR_WIDTH shl 16
	mov [font_current_char_rect].pos.x, FONT_SM_CHAR_WIDTH * 2
	call screen_draw1bppSprite

	pop r14
	pop r10
	pop r9
	pop r8
	pop rsi
	pop rdx
	pop rcx
	pop rbx
	_ret:
	ret
title_drawCredit endp


endif