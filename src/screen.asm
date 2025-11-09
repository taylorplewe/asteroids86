%ifndef screen_h
%define screen_h

%include "src/globaldefs.inc"

%include "src/font.asm"


section .data

cosmic_color:
	istruc Pixel
		at .r, db 37h
		at .g, db 94h
		at .b, db 6eh
		at .a, db 0ffh
	iend
press_any_key_text db "PRESS ANY KEY TO CONTINUE"
press_any_key_text_len equ $ - press_any_key_text

screen_width_d_256 dd (256 / 4) dup (SCREEN_WIDTH)
screen_height_d_256 dd (256 / 4) dup (SCREEN_HEIGHT)


section .bss

; pixels                    resb Pixel_size * SCREEN_WIDTH * SCREEN_HEIGHT
pixels                    resq 1
screen_point1             resb Point_size
screen_point2             resb Point_size
x_diff                    resd 1
y_diff                    resd 1
x_add                     resd 1 ; 16.16 fixed point
y_add                     resd 1 ; 16.16 fixed point
is_xdiff_neg              resb 1
is_ydiff_neg              resb 1
screen_show_press_any_key resd 1


section .text

; in:
	; rax - pointer to pixel array
%macro screen_setPixelPtr 0
	mov [pixels], rax
%endmacro

; in:
	; ebx  - x
	; ecx  - y
	; r8d  - color
	; rdi  - point to pixels
	; r14d - SCREEN_WIDTH
	; r15d - SCREEN_HEIGHT
; clobbers:
	; rdx
	; r13
%macro screen_setPixelWrapped 0
	; wrap x
	mov eax, ebx
	add eax, r14d
	cdq
	div r14d
	imul edx, Pixel_size
	mov r13d, edx
	; wrap y
	mov eax, ecx
	add eax, r15d
	cdq
	div r15d
	imul edx, SCREEN_WIDTH * Pixel_size
	add r13d, edx
	; plot pixel
	mov [rdi + r13], r8d
	; NOTE: I tried changing the above instruction to an 'add' to get transparent objects on top of each other to work. It mostly worked, but is funky with colors, like the fire.
%endmacro

; in:
	; ebx  - x
	; ecx  - y
	; r8d  - color
	; rdi  - point to pixels
screen_setPixelClipped:
	test ebx, ebx
	js .end
	cmp ebx, SCREEN_WIDTH
	jge .end

	test ecx, ecx
	js .end
	cmp ecx, SCREEN_HEIGHT
	jl ._
	.end: ret
	._:
	; fall thru


; in:
	; ebx  - x
	; ecx  - y
	; r8d  - color
	; rdi  - point to pixels
screen_setPixelOnscreenVerified:
	mov eax, ecx
	imul eax, SCREEN_WIDTH
	add eax, ebx
	imul eax, Pixel_size

	; plot pixel
	mov [rdi + rax], r8d

	ret

; Draws 8 pixels to the screen
; in:
	; ymm2[dwords] - x
	; ymm3[dwords] - y
	; ymm4[dwords] - color
	; rdi          - point to pixels
screen_setPixelOnscreenVerifiedSimd:
	push rbx
	push rbp
	mov rbp, rsp
	sub rsp, 64

	vpmulld ymm3, ymm3, yword [screen_width_d_256] ; foreach y: y *= SCREEN_WIDTH
	vpaddd ymm3, ymm3, ymm2                              ; foreach x,y: ind = y + x
	vpslld ymm3, ymm3, 2                                 ; foreach ind: ind *= sizeof Pixel (which is 4) (<< 2)
	vmovdqu yword [rsp], ymm3
	vmovdqu yword [rsp + 32], ymm4 ; store all the colors

	%assign i 0
	%rep 8
		mov eax, [rsp + i]
		mov ebx, [rsp + 32 + i]
		mov [rdi + rax], ebx
		%assign i i + 4
	%endrep

	mov rsp, rbp
	pop rbp
	pop rbx
	ret

; in:
	; ebx  - x
	; ecx  - y
	; r8d  - color
	; rdi  - point to pixels
screen_draw3difiedPixelOnscreenVerified:
	push rbx
	push rcx
	push r8

	; 3d effect
	mov r8d, dword [cosmic_color]

	%rep 6
	inc ebx
	inc ecx
	call screen_setPixelOnscreenVerified
	%endrep

	pop r8
	pop rcx
	pop rbx

	jmp screen_setPixelOnscreenVerified

	; ret


; in:
	; ebx  - x
	; ecx  - y
	; r8d  - color
	; rdi  - point to pixels
	; r14d - SCREEN_WIDTH
	; r15d - SCREEN_HEIGHT
%macro screen_plotPoint 0
	screen_setPixelWrapped
	dec ebx
	screen_setPixelWrapped
	add ebx, 2
	screen_setPixelWrapped
	dec ebx
	dec ecx
	screen_setPixelWrapped
	add ecx, 2
	screen_setPixelWrapped
	dec ecx
%endmacro

; Draws a 1bpp sprite comprised of a bitplane; one byte represents 8 pixels in a row.
; Position should be in the center of the drawn sprite.
; in:
	; rdx - pointer to onscreen Point to draw sprite (16.16 fixed point)
	; rsi - pointer to beginning of sprite data
	; r8d - color
	; r9  - pointer to in-spritesheet Rect, dimensions of sprite
	; r14 - pointer to pixel plotting routine to call
screen_draw1bppSprite:
	push rbx
	push rcx
	push rsi
	push rdi
	push r10
	push r11
	push r12
	push r13

	mov rdi, [pixels]

	mov r13, rsi
	add rsi, Dim_size

	; NOTE: will need to add Y pos logic here if ever have a spritesheet with multiple rows of sprites
	mov eax, [r9 + Rect.pos + Point.x]
	shr eax, 3 ; /8
	add rsi, rax

	; set x
	xor eax, eax
	mov ax, word [rdx + Point.x + 2]
	cwde
	mov ebx, [r9 + Rect.dim + Dim.w]
	sar ebx, 1
	sub eax, ebx
	mov ebx, eax
	; set y
	xor eax, eax
	mov ax, word [rdx + Point.y + 2]
	cwde
	mov ecx, [r9 + Rect.dim + Dim.h]
	sar ecx, 1
	sub eax, ecx
	mov ecx, eax
	; w and h counters
	mov r10d, [r9 + Rect.dim + Dim.w]
	mov r11d, [r9 + Rect.dim + Dim.h]

	xor r12d, r12d ; bit position index

	.rowLoop:
		.colLoop:
			; cmp byte [rsi], 0
			bt word [rsi], r12w
			jnc .colNext
			call r14
			
			.colNext:
			inc r12w
			and r12w, 7
			jne ._
				inc rsi
			._:

			inc ebx
			dec r10d
			jne .colLoop
		.rowNext:	
		; wrap around to next line of pixels in this particular rect
		mov eax, [r13 + Dim.w]
		add rsi, rax
		mov eax, [r9 + Rect.dim + Dim.w]
		shr eax, 3 ; /8
		sub rsi, rax

		sub ebx, [r9 + Rect.dim + Dim.w]
		mov r10d, [r9 + Rect.dim + Dim.w]
		inc ecx
		dec r11d
		jne .rowLoop

	pop r13
	pop r12
	pop r11
	pop r10
	pop rdi
	pop rsi
	pop rcx
	pop rbx
	ret


; TODO: this routine is pretty gnarly with the stack frame. Can probably be improved.
; in:
	; ebx - x
	; ecx - y
	; edx - circle radius
	; r8d - color
	; r14d - SCREEN_WIDTH
	; r15d - SCREEN_HEIGHT
screen_drawCircle:
	push rbp
	push rdi
	mov rbp, rsp
	sub rsp, 24

	mov rdi, [pixels]

	mov dword [rsp + 8], ebx
	mov dword [rsp + 12], ecx
	sub ebx, edx
	sub ecx, edx

	mov dword [rsp + 20], edx
	shl dword [rsp + 20], 1
	imul edx, edx
	mov dword [rsp + 16], edx
	mov edx, dword [rsp + 20]

	mov dword [rsp + 4], edx
	.rowLoop:
		mov dword [rsp], edx
		.colLoop:
			; inside circle if (dx^2 + dy^2) < r^2
			mov eax, ebx
			sub eax, dword [rsp + 8]
			imul eax, eax
			mov edx, ecx
			sub edx, dword [rsp + 12]
			imul edx, edx
			add eax, edx
			cmp eax, dword [rsp + 16]
			jge .colLoopNext

			screen_setPixelWrapped

			.colLoopNext:
			inc ebx
			dec dword [rsp]
			jne .colLoop
		.rowLoopNext:
		mov edx, dword [rsp + 20]
		sub ebx, edx
		inc ecx
		dec dword [rsp + 4]
		jne .rowLoop

	mov rsp, rbp
	pop rdi
	pop rbp
	ret


%macro screen_mDrawLine 2 ;point1:req, point2:req
	mov eax, [%1 + Point.x]
	mov [screen_point1 + Point.x], eax
	mov eax, [%1 + Point.y]
	mov [screen_point1 + Point.y], eax
	mov eax, [%2 + Point.x]
	mov [screen_point2 + Point.x], eax
	mov eax, [%2 + Point.y]
	mov [screen_point2 + Point.y], eax
	call screen_drawLine
%endmacro

; TODO: convert statically allocated bss variables to stack variables
; in:
	; r8d - color to draw
	; point1
	; point2
; clobbers:
	; rax
	; rbx
	; rcx
	; rdx
	; rdi
	; r10
	; r11
	; r13
	; r14
	; r15
screen_drawLine:
	mov byte [is_xdiff_neg], 0
	mov byte [is_ydiff_neg], 0

	; rdi = pointer into pixels
	mov rdi, [pixels]
	mov r14d, SCREEN_WIDTH
	mov r15d, SCREEN_HEIGHT

	; x_diff = |p2.x - p1.x|
	mov eax, [screen_point2 + Point.x]
	sub eax, [screen_point1 + Point.x]
	mov ebx, eax
	shl ebx, 1
	rcl byte [is_xdiff_neg], 1
	abseax
	mov [x_diff], eax
	
	; y_diff = |p2.y - p1.y|
	mov eax, [screen_point2 + Point.y]
	sub eax, [screen_point1 + Point.y]
	mov ebx, eax
	shl ebx, 1
	rcl byte [is_ydiff_neg], 1
	abseax
	mov [y_diff], eax

	; if both are zero, exit
	test eax, eax
	jne ._
	cmp [x_diff], 0
	jne ._
	ret
	._:

	cmp eax, [x_diff]
	jl .xDiffGreater
	.yDiffGreater:
		; x_add = x_diff / y_diff
		mov eax, [x_diff]
		shl eax, 16
		cdq
		mov ebx, [y_diff]
		idiv ebx
		mov [x_add], eax

		mov ebx, [screen_point1 + Point.x]
		mov ecx, [screen_point1 + Point.y]

		mov r11d, [y_diff]
		mov r10d, 00008000h ; 0.5 fixed point
		cmp byte [is_ydiff_neg], 0
		je .yIncLoop
		.yDecLoop:
			cmp byte [is_xdiff_neg], 0
			je .yDecXIncLoop
			.yDecXDecLoop:
				screen_plotPoint
				dec ecx

				add r10d, [x_add]
				cmp r10d, 00010000h
				jl ._1
				dec ebx
				and r10d, 0000ffffh
				._1:

				dec r11d
				jne .yDecXDecLoop
			ret
			.yDecXIncLoop:
				screen_plotPoint
				dec ecx

				add r10d, [x_add]
				cmp r10d, 00010000h
				jl ._2
				inc ebx
				and r10d, 0000ffffh
				._2:

				dec r11d
				jne .yDecXIncLoop
			ret
		.yIncLoop:
			cmp byte [is_xdiff_neg], 0
			je .yIncXIncLoop
			.yIncXDecLoop:
				screen_plotPoint
				inc ecx

				add r10d, [x_add]
				cmp r10d, 00010000h
				jl ._3
				dec ebx
				and r10d, 0000ffffh
				._3:

				dec r11d
				jne .yIncXDecLoop
			ret
			.yIncXIncLoop:
				screen_plotPoint
				inc ecx

				add r10d, [x_add]
				cmp r10d, 00010000h
				jl ._4
				inc ebx
				and r10d, 0000ffffh
				._4:

				dec r11d
				jne .yIncXIncLoop
			ret
	.xDiffGreater:
		; x_add = x_diff / y_diff
		mov eax, [y_diff]
		shl eax, 16
		cdq
		mov ebx, [x_diff]
		idiv ebx
		mov [y_add], eax

		mov ebx, [screen_point1 + Point.x]
		mov ecx, [screen_point1 + Point.y]

		mov r11d, [x_diff]
		mov r10d, 00008000h ; 0.5 fixed point
		cmp byte [is_xdiff_neg], 0
		je .xIncLoop
		.xDecLoop:
			cmp byte [is_ydiff_neg], 0
			je .xDecYIncLoop
			.xDecYDecLoop:
				screen_plotPoint
				dec ebx

				add r10d, [y_add]
				cmp r10d, 00010000h
				jl ._5
				dec ecx
				and r10d, 0000ffffh
				._5:

				dec r11d
				jne .xDecYDecLoop
			ret
			.xDecYIncLoop:
				screen_plotPoint
				dec ebx

				add r10d, [y_add]
				cmp r10d, 00010000h
				jl ._6
				inc ecx
				and r10d, 0000ffffh
				._6:

				dec r11d
				jne .xDecYIncLoop
			ret
		.xIncLoop:
			cmp byte [is_ydiff_neg], 0
			je .xIncYIncLoop
			.xIncYDecLoop:
				screen_plotPoint
				inc ebx

				add r10d, [y_add]
				cmp r10d, 00010000h
				jl ._7
				dec ecx
				and r10d, 0000ffffh
				._7:

				dec r11d
				jne .xIncYDecLoop
			ret
			.xIncYIncLoop:
				screen_plotPoint
				inc ebx

				add r10d, [y_add]
				cmp r10d, 00010000h
				jl ._8
				inc ecx
				and r10d, 0000ffffh
				._8:

				dec r11d
				jne .xIncYIncLoop
			ret
	ret


PRESS_ANY_KEY_KERNING    equ 4
PRESS_ANY_KEY_CHAR_WIDTH equ FONT_SM_CHAR_WIDTH + PRESS_ANY_KEY_KERNING
PRESS_ANY_KEY_FULL_WIDTH equ (press_any_key_text_len * PRESS_ANY_KEY_CHAR_WIDTH) - PRESS_ANY_KEY_KERNING
PRESS_ANY_KEY_FIRST_X    equ (((SCREEN_WIDTH / 2) - (PRESS_ANY_KEY_FULL_WIDTH / 2)) + (FONT_SM_CHAR_WIDTH / 2)) << 16

; in:
	; set [font_current_char_pos].y
screen_drawPressAnyKey:
	cmp dword [screen_show_press_any_key], 0
	je ._ret

	push rbx
	push rcx
	push rdx
	push rsi
	push r8
	push r9
	push r14

	lea rdx, font_current_char_pos
	lea rsi, font_small_spr_data
	mov r8d, [gray_color]
	lea r9, font_current_char_rect
	lea r14, screen_setPixelOnscreenVerified

	mov dword [font_current_char_pos + Point.x], PRESS_ANY_KEY_FIRST_X
	mov dword [font_current_char_rect + Rect.pos + Point.x], 0
	mov dword [font_current_char_rect + Rect.pos + Point.y], 0
	mov dword [font_current_char_rect + Rect.dim + Dim.w], FONT_SM_CHAR_WIDTH
	mov dword [font_current_char_rect + Rect.dim + Dim.h], FONT_SM_CHAR_HEIGHT

	lea rbx, press_any_key_text
	xor ecx, ecx
	.charLoop:
		xor eax, eax
		mov al, cl
		xlatb ; Table Look-up Translation; al = byte [rbx + al]
		cmp al, ' '
		je .drawCharEnd
		sub al, 'A'
		imul eax, FONT_SM_CHAR_WIDTH
		mov [font_current_char_rect + Rect.pos + Point.x], eax

		call screen_draw1bppSprite

		.drawCharEnd:
		add dword [font_current_char_pos + Point.x], PRESS_ANY_KEY_CHAR_WIDTH << 16

		inc ecx
		cmp ecx, press_any_key_text_len
		jl .charLoop

	pop r14
	pop r9
	pop r8
	pop rsi
	pop rdx
	pop rcx
	pop rbx
	._ret:
	ret


screen_clearPixelBuffer:
	mov ecx, (SCREEN_WIDTH * SCREEN_HEIGHT * 4) / 32
	mov rdi, [pixels]
	vmovdqu ymm0, yword [zero64]
	.loop:
		vmovdqu yword [rdi], ymm0
		add rdi, 32
		loop .loop
	ret



%endif