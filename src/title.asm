%ifndef title_h
%define title_h

%include "src/globaldefs.inc"
%include "src/data/title-points.inc"

%include "src/global.asm"
%include "src/screen.asm"


TITLE_APPEAR_DELAY_COUNTER_AMT     equ 60 * 2
TITLE_MAX_NUM_LINES_TO_DRAW        equ 33
TITLE_NUM_FRAMES                   equ 3
TITLE_FRAME_TIME                   equ 12
TITLE_86_FLICKER_DELAY_COUNTER_AMT equ 60 * 2
TITLE_PRESS_ANY_KEY_Y              equ ((SCREEN_HEIGHT / 2) + (SCREEN_HEIGHT / 4)) << 16
TITLE_PRESS_ANY_KEY_COUNTER_AMT    equ 60 * 4


section .bss

title_point1     resb Point_size
title_point2     resb Point_size

; animation
title_appear_delay_counter       resd 1
title_num_lines_to_draw          resd 1
title_anim_frame                 resd 1
title_anim_counter               resd 1
title_86_flicker_delay_counter   resd 1
title_86_flicker_inds            resd 2
title_show_press_any_key_counter resd 1


section .text

title_init:
	mov dword [title_appear_delay_counter], TITLE_APPEAR_DELAY_COUNTER_AMT
	mov dword [title_num_lines_to_draw], 0
	mov dword [title_anim_frame], 0
	mov dword [title_anim_counter], 0
	mov dword [title_86_flicker_delay_counter], 0
	mov dword [title_86_flicker_inds], 0
	mov dword [title_show_press_any_key_counter], 0
	mov dword [screen_show_press_any_key], 0

	ret


; in:
	; rdi - pointer to Input struct
title_tick:
	cmp dword [rdi + Input.buttons_pressed], 0
	je .anyKeyPressEnd
		cmp dword [screen_show_press_any_key], 0
		je ._
			call game_init
			mov [mode], Mode_Game
			ret
		._:
			call title_skipAnim
	.anyKeyPressEnd:

	cmp [title_show_press_any_key_counter], 0
	je ._2
		dec dword [title_show_press_any_key_counter]
		jne ._2
		inc dword [screen_show_press_any_key]
	._2:

	; sweep left to right drawing lines
	mov eax, [title_num_lines_to_draw]
	test eax, eax
	je ._3
	cmp eax, TITLE_MAX_NUM_LINES_TO_DRAW
	jge ._3
		inc eax
		mov [title_num_lines_to_draw], eax
		cmp eax, TITLE_MAX_NUM_LINES_TO_DRAW
		jl ._3
		mov dword [title_86_flicker_delay_counter], TITLE_86_FLICKER_DELAY_COUNTER_AMT
		mov dword [title_show_press_any_key_counter], TITLE_PRESS_ANY_KEY_COUNTER_AMT
	._3:

	; appear delay counter
	cmp dword [title_appear_delay_counter], 0
	je ._4
		dec dword [title_appear_delay_counter]
		jne ._4
		inc dword [title_num_lines_to_draw]
	._4:

	; advance ASTEROIDS animation
	inc [title_anim_counter]
	cmp dword [title_anim_counter], TITLE_FRAME_TIME
	jl ._5
	jne ._5
		mov dword [title_anim_counter], 0
		inc [title_anim_frame]
		cmp dword [title_anim_frame], 3
		jl ._5
		mov dword [title_anim_frame], 0
	._5:

	; advance 86 flicker
	cmp dword [title_86_flicker_inds], 0
	je ._6

		cmp dword [title_86_flicker_inds], flicker_alphas_len
		jge ._6_1
		inc [title_86_flicker_inds]
		._6_1:
		cmp dword [title_86_flicker_inds + 4], flicker_alphas_len
		jge ._6_2
		inc [title_86_flicker_inds + 4]
		._6_2:
	._6:

	; count down 86 appear delay
	cmp dword [title_86_flicker_delay_counter], 0
	je ._86FlickerDelayEnd
		dec [title_86_flicker_delay_counter]
		jne ._86FlickerDelayEnd
		; generate 2 random indexes into the flicker array
		rand eax
		and eax, 11111b
		inc eax
		mov dword [title_86_flicker_inds], eax
		rand eax
		and eax, 11111b
		inc eax
		mov dword [title_86_flicker_inds + 4], eax
	._86FlickerDelayEnd:

	ret

title_draw:
	call title_drawAsteroids
	call title_draw86
	call title_drawCredit

	; "Press any key to continue"
	cmp dword [screen_show_press_any_key], 0
	je ._
		mov dword [font_current_char_pos + Point.y], TITLE_PRESS_ANY_KEY_Y
		call screen_drawPressAnyKey
	._:
	ret

title_skipAnim:
	mov dword [title_appear_delay_counter], 0
	mov dword [title_86_flicker_delay_counter], 0
	mov dword [title_show_press_any_key_counter], 0

	mov dword [title_num_lines_to_draw], TITLE_MAX_NUM_LINES_TO_DRAW
	mov dword [title_86_flicker_inds], flicker_alphas_len - 1
	mov dword [title_86_flicker_inds + 4], flicker_alphas_len - 1
	mov dword [screen_show_press_any_key], 1
	ret


; in:
	; ebx - index
title_drawLine:
	xor eax, eax
	mov ax, [rsi]
	mov [screen_point1 + Point.x], eax
	mov ax, [rsi + 2]
	mov [screen_point1 + Point.y], eax
	mov ax, [rsi + 4]
	mov [screen_point2 + Point.x], eax
	mov ax, [rsi + 6]
	mov [screen_point2 + Point.y], eax
	push rcx
	call screen_drawLine
	pop rcx
	ret


title_drawAsteroids:
	cmp dword [title_appear_delay_counter], 0
	jne ._ret

	push rcx
	push rsi
	push r8

	lea rsi, title_points_tab
	mov eax, [title_anim_frame]
	shl eax, 3
	mov rsi, [rsi + rax]
	mov r8d, [fg_color]

	mov ecx, [title_num_lines_to_draw]
	; for ind, <4, 8, 8, 4, 4, 4, 4, 8, 8, 8, 4, 4, 8, 8, 4, 4, 4, 8, 8, 4, 4, 4, 8, 8, 4, 4, 4, 8, 4, 4, 4, 4, 0>
	; 	call title_drawLine
	; 	add rsi, ind
	; 	dec ecx
	; 	je .end
	; endm

	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 8
	dec ecx
	je .end
	call title_drawLine
	add rsi, 8
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 8
	dec ecx
	je .end
	call title_drawLine
	add rsi, 8
	dec ecx
	je .end
	call title_drawLine
	add rsi, 8
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 8
	dec ecx
	je .end
	call title_drawLine
	add rsi, 8
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 8
	dec ecx
	je .end
	call title_drawLine
	add rsi, 8
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 8
	dec ecx
	je .end
	call title_drawLine
	add rsi, 8
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 8
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 4
	dec ecx
	je .end
	call title_drawLine
	add rsi, 0
	dec ecx
	je .end
	
 	; close the D
	xor eax, eax
	mov ax, [rsi + 148]
	mov [screen_point1 + Point.x], eax
	mov ax, [rsi + 150]
	mov [screen_point1 + Point.y], eax
	mov ax, [rsi + 136]
	mov [screen_point2 + Point.x], eax
	mov ax, [rsi + 138]
	mov [screen_point2 + Point.y], eax
	call screen_drawLine

	.end:
	pop r8
	pop rsi
	pop rcx
	._ret:
	ret


title_draw86:
	cmp dword [title_86_flicker_inds], 0
	je ._ret

	push rdx
	push rsi
	push rdi
	push r8
	push r9
	push r14

	lea rdx, font_current_char_pos
	; mov rsi, [font_digits_spr_data]
	lea rsi, font_digits_spr_data
	mov r8d, [fg_color]
	lea r9, font_current_char_rect
	lea r14, screen_setPixelOnscreenVerified

	mov dword [font_current_char_pos + Point.x], 1010 << 16
	mov dword [font_current_char_pos + Point.y], 428 << 16
	mov dword [font_current_char_rect + Rect.pos + Point.x], 8 * FONT_DIGIT_WIDTH
	mov dword [font_current_char_rect + Rect.pos + Point.y], 0
	mov dword [font_current_char_rect + Rect.dim + Dim.w], FONT_DIGIT_WIDTH
	mov dword [font_current_char_rect + Rect.dim + Dim.h], FONT_DIGIT_HEIGHT

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

	add dword [font_current_char_pos + Point.x], (FONT_DIGIT_WIDTH + 5) << 16
	mov dword [font_current_char_rect + Rect.pos + Point.x], 6 * FONT_DIGIT_WIDTH

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
	._ret:
	ret


TITLE_CREDIT_X equ ((SCREEN_WIDTH / 2) + 248) << 16
TITLE_CREDIT_Y equ (SCREEN_HEIGHT - 32) << 16
my_name db "TAYLOR PLEWE"
my_name_len equ $ - my_name
title_drawCredit:
	cmp dword [screen_show_press_any_key], 0
	je ._ret

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
	mov dword [font_current_char_pos + Point.x], TITLE_CREDIT_X
	mov dword [font_current_char_pos + Point.y], TITLE_CREDIT_Y

	; copyright symbol
	lea rsi, font_copyright_spr_data
	mov dword [font_current_char_rect + Rect.pos + Point.x], 0
	mov dword [font_current_char_rect + Rect.pos + Point.y], 0
	mov dword [font_current_char_rect + Rect.dim + Dim.w], FONT_COPYRIGHT_WIDTH
	mov dword [font_current_char_rect + Rect.dim + Dim.h], FONT_COPYRIGHT_HEIGHT
	call screen_draw1bppSprite

	add dword [font_current_char_pos + Point.x], (PRESS_ANY_KEY_CHAR_WIDTH + 8) << 16

	; my name
	mov dword [font_current_char_rect + Rect.dim + Dim.h], FONT_SM_CHAR_HEIGHT
	lea rbx, my_name
	xor ecx, ecx
	xor r10, r10
	.nameLoop:
		xor eax, eax
		mov al, cl
		xlatb ; Table Look-up Translation; al = byte [rbx + al]
		cmp al, ' '
		je .nameLoopDrawCharEnd
		cmp al, 'W'
		sete r10b
		je .nameLoopW
			sub al, 'A'
			lea rsi, font_small_spr_data
			mov dword [font_current_char_rect + Rect.dim + Dim.w], FONT_SM_CHAR_WIDTH
			imul eax, FONT_SM_CHAR_WIDTH
			jmp .nameLoopCharRectSetEnd
		.nameLoopW:
			add dword [font_current_char_pos + Point.x], (FONT_SM_CHAR_WIDTH / 2) << 16
			lea rsi, font_small_w_spr_data
			mov dword [font_current_char_rect + Rect.dim + Dim.w], FONT_SM_W_WIDTH
			mov eax, 0
		.nameLoopCharRectSetEnd:
		mov [font_current_char_rect + Rect.pos + Point.x], eax

		call screen_draw1bppSprite

		.nameLoopDrawCharEnd:
		add dword [font_current_char_pos + Point.x], PRESS_ANY_KEY_CHAR_WIDTH << 16
		test r10, r10
		je ._
			add dword [font_current_char_pos + Point.x], (FONT_SM_CHAR_WIDTH / 2) << 16
		._:

		inc ecx
		cmp ecx, my_name_len
		jl .nameLoop

	add dword [font_current_char_pos + Point.x], PRESS_ANY_KEY_CHAR_WIDTH << 16

	; creation year
	lea rsi, font_yr_digits_spr_data
	mov dword [font_current_char_rect + Rect.dim + Dim.w], FONT_SM_CHAR_WIDTH
	mov dword [font_current_char_rect + Rect.pos + Point.x], 0
	call screen_draw1bppSprite

	add dword [font_current_char_pos + Point.x], PRESS_ANY_KEY_CHAR_WIDTH << 16
	mov dword [font_current_char_rect + Rect.pos + Point.x], FONT_SM_CHAR_WIDTH
	call screen_draw1bppSprite

	add dword [font_current_char_pos + Point.x], PRESS_ANY_KEY_CHAR_WIDTH << 16
	mov dword [font_current_char_rect + Rect.pos + Point.x], 0
	call screen_draw1bppSprite

	add dword [font_current_char_pos + Point.x], PRESS_ANY_KEY_CHAR_WIDTH << 16
	mov dword [font_current_char_rect + Rect.pos + Point.x], FONT_SM_CHAR_WIDTH * 2
	call screen_draw1bppSprite

	pop r14
	pop r10
	pop r9
	pop r8
	pop rsi
	pop rdx
	pop rcx
	pop rbx
	._ret:
	ret



%endif