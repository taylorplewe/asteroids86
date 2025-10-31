ifndef title_h
title_h = 1

include <globaldefs.inc>
include <data\title-points.inc>

include <global.s>
include <screen.s>


TITLE_NUM_FRAMES = 3
TITLE_FRAME_TIME = 12


.data?

title_point1       Point <>
title_point2       Point <>
title_anim_frame   dd    ?
title_anim_counter dd    ?


.code

title_tick proc
	call title_drawAsteroids

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
	lea rdx, font_current_char_pos
	mov rsi, [font_digits_spr_data]
	mov r8d, [fg_color]
	lea r9, font_current_char_rect
	lea r14, screen_draw3difiedPixelOnscreenVerified

	; rdx - pointer to onscreen Point to draw sprite (16.16 fixed point)
	; rsi - pointer to beginning of sprite data
	; r8d - color
	; r9  - pointer to in-spritesheet Rect, dimensions of sprite
	; r14 - pointer to pixel plotting routine to call
	call screen_draw1bppSprite

	ret
title_draw86 endp


endif
