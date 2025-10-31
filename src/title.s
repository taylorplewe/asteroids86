ifndef title_h
title_h = 1

include <globaldefs.inc>
include <data\title-points.inc>

include <global.s>
include <screen.s>


.data?

title_point1 Point <>
title_point2 Point <>


.code

title_tick proc
	call title_drawAsteroids

	ret
title_tick endp

title_drawLine macro
	screen_mDrawLine title_point1, title_point2
endm

title_drawAsteroids proc
	lea rsi, title_points_0
	mov r8d, [fg_color]

	xor eax, eax
	mov ax, [rsi]
	mov [title_point1].x, eax
	mov ax, [rsi + 2]
	mov [title_point1].y, eax
	mov ax, [rsi + 4]
	mov [title_point2].x, eax
	mov ax, [rsi + 6]
	mov [title_point2].y, eax
	title_drawLine

	xor eax, eax
	mov ax, [rsi + 8]
	mov [title_point1].x, eax
	mov ax, [rsi + 10]
	mov [title_point1].y, eax
	title_drawLine

	xor eax, eax
	mov ax, [rsi + 12]
	mov [title_point1].x, eax
	mov ax, [rsi + 14]
	mov [title_point1].y, eax
	mov ax, [rsi + 16]
	mov [title_point2].x, eax
	mov ax, [rsi + 18]
	mov [title_point2].y, eax
	title_drawLine

	xor eax, eax
	mov ax, [rsi + 20]
	mov [title_point1].x, eax
	mov ax, [rsi + 22]
	mov [title_point1].y, eax
	mov ax, [rsi + 24]
	mov [title_point2].x, eax
	mov ax, [rsi + 26]
	mov [title_point2].y, eax
	title_drawLine

	xor eax, eax
	mov ax, [rsi + 28]
	mov [title_point1].x, eax
	mov ax, [rsi + 30]
	mov [title_point1].y, eax
	title_drawLine

	xor eax, eax
	mov ax, [rsi + 32]
	mov [title_point2].x, eax
	mov ax, [rsi + 34]
	mov [title_point2].y, eax
	title_drawLine

	xor eax, eax
	mov ax, [rsi + 36]
	mov [title_point1].x, eax
	mov ax, [rsi + 38]
	mov [title_point1].y, eax
	title_drawLine

	xor eax, eax
	mov ax, [rsi + 40]
	mov [title_point2].x, eax
	mov ax, [rsi + 42]
	mov [title_point2].y, eax
	title_drawLine

	xor eax, eax
	mov ax, [rsi + 44]
	mov [title_point1].x, eax
	mov ax, [rsi + 46]
	mov [title_point1].y, eax
	mov ax, [rsi + 48]
	mov [title_point2].x, eax
	mov ax, [rsi + 50]
	mov [title_point2].y, eax
	title_drawLine

	xor eax, eax
	mov ax, [rsi + 52]
	mov [title_point1].x, eax
	mov ax, [rsi + 54]
	mov [title_point1].y, eax
	mov ax, [rsi + 56]
	mov [title_point2].x, eax
	mov ax, [rsi + 58]
	mov [title_point2].y, eax
	title_drawLine

	ret
title_drawAsteroids endp


endif
