ifndef screen_h
screen_h = 1

include <globaldefs.inc>

include <font.s>


.data

cosmic_color       Pixel <37h, 94h, 6eh, 0ffh> ; 37946e
press_any_key_text db "PRESS ANY KEY TO CONTINUE"
press_any_key_text_len = $ - press_any_key_text


.data?

pixels                    Pixel SCREEN_WIDTH*SCREEN_HEIGHT dup (<?>)
screen_point1             Point <?>
screen_point2             Point <?>
x_diff                    dd ?
y_diff                    dd ?
x_add                     dd ? ; 16.16 fixed point
y_add                     dd ? ; 16.16 fixed point
is_xdiff_neg              db ?
is_ydiff_neg              db ?
screen_show_press_any_key dd ?


.code

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
screen_setPixelWrapped macro
	; wrap x
	mov eax, ebx
	add eax, r14d
	cdq
	div r14d
	imul edx, sizeof Pixel
	mov r13d, edx
	; wrap y
	mov eax, ecx
	add eax, r15d
	cdq
	div r15d
	imul edx, SCREEN_WIDTH * sizeof Pixel
	add r13d, edx
	; plot pixel
	mov [rdi + r13], r8d
	; NOTE: I tried changing the above instruction to an 'add' to get transparent objects on top of each other to work. It mostly worked, but is funky with colors, like the fire.
endm

; in:
	; ebx  - x
	; ecx  - y
	; r8d  - color
	; rdi  - point to pixels
screen_setPixelClipped proc
	test ebx, ebx
	js _end
	cmp ebx, SCREEN_WIDTH
	jge _end

	test ecx, ecx
	js _end
	cmp ecx, SCREEN_HEIGHT
	jl @f
	_end: ret
	@@:
	; fall thru
screen_setPixelClipped endp

; in:
	; ebx  - x
	; ecx  - y
	; r8d  - color
	; rdi  - point to pixels
screen_setPixelOnscreenVerified proc
	mov eax, ecx
	imul eax, SCREEN_WIDTH
	add eax, ebx
	imul eax, sizeof Pixel

	; plot pixel
	mov [rdi + rax], r8d

	ret
screen_setPixelOnscreenVerified endp

; in:
	; ebx  - x
	; ecx  - y
	; r8d  - color
	; rdi  - point to pixels
screen_draw3difiedPixelOnscreenVerified proc
	push rbx
	push rcx
	push r8

	; 3d effect
	mov r8d, [cosmic_color]

	repeat 6
	inc ebx
	inc ecx
	call screen_setPixelOnscreenVerified
	endm

	pop r8
	pop rcx
	pop rbx

	jmp screen_setPixelOnscreenVerified

	; ret
screen_draw3difiedPixelOnscreenVerified endp

; in:
	; ebx  - x
	; ecx  - y
	; r8d  - color
	; rdi  - point to pixels
	; r14d - SCREEN_WIDTH
	; r15d - SCREEN_HEIGHT
screen_plotPoint macro
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
endm

; Draws a 1bpp sprite comprised of a bitplane; one byte represents 8 pixels in a row.
; Position should be in the center of the drawn sprite.
; in:
	; rdx - pointer to onscreen Point to draw sprite (16.16 fixed point)
	; rsi - pointer to beginning of sprite data
	; r8d - color
	; r9  - pointer to in-spritesheet Rect, dimensions of sprite
	; r14 - pointer to pixel plotting routine to call
screen_draw1bppSprite proc
	push rbx
	push rcx
	push rsi
	push rdi
	push r10
	push r11
	push r12
	push r13

	lea rdi, pixels

	mov r13, rsi
	add rsi, sizeof Dim

	; NOTE: will need to add Y pos logic here if ever have a spritesheet with multiple rows of sprites
	mov eax, [r9].Rect.pos.x
	shr eax, 3 ; /8
	add rsi, rax

	; set x
	xor eax, eax
	mov ax, word ptr [rdx].Point.x + 2
	cwde
	mov ebx, [r9].Rect.dim.w
	sar ebx, 1
	sub eax, ebx
	mov ebx, eax
	; set y
	xor eax, eax
	mov ax, word ptr [rdx].Point.y + 2
	cwde
	mov ecx, [r9].Rect.dim.h
	sar ecx, 1
	sub eax, ecx
	mov ecx, eax
	; w and h counters
	mov r10d, [r9].Rect.dim.w
	mov r11d, [r9].Rect.dim.h

	xor r12d, r12d ; bit position index

	rowLoop:
		colLoop:
			; cmp byte ptr [rsi], 0
			bt word ptr [rsi], r12w
			jnc colNext
			call r14
			
			colNext:
			inc r12w
			and r12w, 7
			jne @f
				inc rsi
			@@:

			inc ebx
			dec r10d
			jne colLoop
		rowNext:	
		; wrap around to next line of pixels in this particular rect
		mov eax, [r13].Dim.w
		add rsi, rax
		mov eax, [r9].Rect.dim.w
		shr eax, 3 ; /8
		sub rsi, rax

		sub ebx, [r9].Rect.dim.w
		mov r10d, [r9].Rect.dim.w
		inc ecx
		dec r11d
		jne rowLoop

	pop r13
	pop r12
	pop r11
	pop r10
	pop rdi
	pop rsi
	pop rcx
	pop rbx
	ret
screen_draw1bppSprite endp

; TODO: this routine is pretty gnarly with the stack frame. Can probably be improved.
; in:
	; ebx - x
	; ecx - y
	; edx - circle radius
	; r8d - color
	; r14d - SCREEN_WIDTH
	; r15d - SCREEN_HEIGHT
screen_drawCircle proc
	push rbp
	push rdi
	mov rbp, rsp
	sub rsp, 24

	lea rdi, pixels

	mov dword ptr [rsp + 8], ebx
	mov dword ptr [rsp + 12], ecx
	sub ebx, edx
	sub ecx, edx

	mov dword ptr [rsp + 20], edx
	shl dword ptr [rsp + 20], 1
	imul edx, edx
	mov dword ptr [rsp + 16], edx
	mov edx, dword ptr [rsp + 20]

	mov dword ptr [rsp + 4], edx
	rowLoop:
		mov dword ptr [rsp], edx
		colLoop:
			; inside circle if (dx^2 + dy^2) < r^2
			mov eax, ebx
			sub eax, dword ptr [rsp + 8]
			imul eax, eax
			mov edx, ecx
			sub edx, dword ptr [rsp + 12]
			imul edx, edx
			add eax, edx
			cmp eax, dword ptr [rsp + 16]
			jge colLoopNext

			screen_setPixelWrapped

			colLoopNext:
			inc ebx
			dec dword ptr [rsp]
			jne colLoop
		rowLoopNext:
		mov edx, dword ptr [rsp + 20]
		sub ebx, edx
		inc ecx
		dec dword ptr [rsp + 4]
		jne rowLoop

	mov rsp, rbp
	pop rdi
	pop rbp
	ret
screen_drawCircle endp

screen_mDrawLine macro point1:req, point2:req
	mov eax, [point1].Point.x
	mov [screen_point1].x, eax
	mov eax, [point1].Point.y
	mov [screen_point1].y, eax
	mov eax, [point2].Point.x
	mov [screen_point2].x, eax
	mov eax, [point2].Point.y
	mov [screen_point2].y, eax
	call screen_drawLine
endm

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
screen_drawLine proc
	mov [is_xdiff_neg], 0
	mov [is_ydiff_neg], 0

	; rdi = pointer into pixels
	lea rdi, pixels
	mov r14d, SCREEN_WIDTH
	mov r15d, SCREEN_HEIGHT

	; x_diff = |p2.x - p1.x|
	mov eax, [screen_point2].x
	sub eax, [screen_point1].x
	mov ebx, eax
	shl ebx, 1
	rcl [is_xdiff_neg], 1
	abseax
	mov [x_diff], eax
	
	; y_diff = |p2.y - p1.y|
	mov eax, [screen_point2].y
	sub eax, [screen_point1].y
	mov ebx, eax
	shl ebx, 1
	rcl [is_ydiff_neg], 1
	abseax
	mov [y_diff], eax

	; if both are zero, exit
	test eax, eax
	jne @f
	cmp [x_diff], 0
	jne @f
	ret
	@@:

	cmp eax, [x_diff]
	jl xDiffGreater
	yDiffGreater:
		; x_add = x_diff / y_diff
		mov eax, [x_diff]
		shl eax, 16
		cdq
		mov ebx, [y_diff]
		idiv ebx
		mov [x_add], eax

		mov ebx, [screen_point1].x
		mov ecx, [screen_point1].y

		mov r11d, [y_diff]
		mov r10d, 00008000h ; 0.5 fixed point
		cmp [is_ydiff_neg], 0
		je yIncLoop
		yDecLoop:
			cmp [is_xdiff_neg], 0
			je yDecXIncLoop
			yDecXDecLoop:
				screen_plotPoint
				dec ecx

				add r10d, [x_add]
				cmp r10d, 00010000h
				jl @f
				dec ebx
				and r10d, 0000ffffh
				@@:

				dec r11d
				jne yDecXDecLoop
			ret
			yDecXIncLoop:
				screen_plotPoint
				dec ecx

				add r10d, [x_add]
				cmp r10d, 00010000h
				jl @f
				inc ebx
				and r10d, 0000ffffh
				@@:

				dec r11d
				jne yDecXIncLoop
			ret
		yIncLoop:
			cmp [is_xdiff_neg], 0
			je yIncXIncLoop
			yIncXDecLoop:
				screen_plotPoint
				inc ecx

				add r10d, [x_add]
				cmp r10d, 00010000h
				jl @f
				dec ebx
				and r10d, 0000ffffh
				@@:

				dec r11d
				jne yIncXDecLoop
			ret
			yIncXIncLoop:
				screen_plotPoint
				inc ecx

				add r10d, [x_add]
				cmp r10d, 00010000h
				jl @f
				inc ebx
				and r10d, 0000ffffh
				@@:

				dec r11d
				jne yIncXIncLoop
			ret
	xDiffGreater:	
		; x_add = x_diff / y_diff
		mov eax, [y_diff]
		shl eax, 16
		cdq
		mov ebx, [x_diff]
		idiv ebx
		mov [y_add], eax

		mov ebx, [screen_point1].x
		mov ecx, [screen_point1].y

		mov r11d, [x_diff]
		mov r10d, 00008000h ; 0.5 fixed point
		cmp [is_xdiff_neg], 0
		je xIncLoop
		xDecLoop:
			cmp [is_ydiff_neg], 0
			je xDecYIncLoop
			xDecYDecLoop:
				screen_plotPoint
				dec ebx

				add r10d, [y_add]
				cmp r10d, 00010000h
				jl @f
				dec ecx
				and r10d, 0000ffffh
				@@:

				dec r11d
				jne xDecYDecLoop
			ret
			xDecYIncLoop:
				screen_plotPoint
				dec ebx

				add r10d, [y_add]
				cmp r10d, 00010000h
				jl @f
				inc ecx
				and r10d, 0000ffffh
				@@:

				dec r11d
				jne xDecYIncLoop
			ret
		xIncLoop:
			cmp [is_ydiff_neg], 0
			je xIncYIncLoop
			xIncYDecLoop:
				screen_plotPoint
				inc ebx

				add r10d, [y_add]
				cmp r10d, 00010000h
				jl @f
				dec ecx
				and r10d, 0000ffffh
				@@:

				dec r11d
				jne xIncYDecLoop
			ret
			xIncYIncLoop:
				screen_plotPoint
				inc ebx

				add r10d, [y_add]
				cmp r10d, 00010000h
				jl @f
				inc ecx
				and r10d, 0000ffffh
				@@:

				dec r11d
				jne xIncYIncLoop
			ret
	ret
screen_drawLine endp

PRESS_ANY_KEY_KERNING    = 4
PRESS_ANY_KEY_CHAR_WIDTH = FONT_SM_CHAR_WIDTH + PRESS_ANY_KEY_KERNING
PRESS_ANY_KEY_FULL_WIDTH = (press_any_key_text_len * PRESS_ANY_KEY_CHAR_WIDTH) - PRESS_ANY_KEY_KERNING
PRESS_ANY_KEY_FIRST_X    = (((SCREEN_WIDTH / 2) - (PRESS_ANY_KEY_FULL_WIDTH / 2)) + (FONT_SM_CHAR_WIDTH / 2)) shl 16

; in:
	; set [font_current_char_pos].y
screen_drawPressAnyKey proc
	cmp [screen_show_press_any_key], 0
	je _ret

	push rbx
	push rcx
	push rdx
	push rsi
	push r8
	push r9
	push r14

	lea rdx, font_current_char_pos
	mov rsi, [font_small_spr_data]
	mov r8d, [gray_color]
	lea r9, font_current_char_rect
	lea r14, screen_setPixelOnscreenVerified

	mov [font_current_char_pos].x, PRESS_ANY_KEY_FIRST_X
	mov [font_current_char_rect].pos.x, 0
	mov [font_current_char_rect].pos.y, 0
	mov [font_current_char_rect].dim.w, FONT_SM_CHAR_WIDTH
	mov [font_current_char_rect].dim.h, FONT_SM_CHAR_HEIGHT

	lea rbx, press_any_key_text
	xor ecx, ecx
	charLoop:
		xor eax, eax
		mov al, cl
		xlatb ; Table Look-up Translation; al = byte ptr [rbx + al]
		cmp al, ' '
		je drawCharEnd
		sub al, 'A'
		imul eax, FONT_SM_CHAR_WIDTH
		mov [font_current_char_rect].pos.x, eax

		call screen_draw1bppSprite

		drawCharEnd:
		add [font_current_char_pos].x, PRESS_ANY_KEY_CHAR_WIDTH shl 16

		inc ecx
		cmp ecx, press_any_key_text_len
		jl charLoop

	pop r14
	pop r9
	pop r8
	pop rsi
	pop rdx
	pop rcx
	pop rbx
	_ret:
	ret
screen_drawPressAnyKey endp

screen_clearPixelBuffer proc
	mov ecx, (SCREEN_WIDTH*SCREEN_HEIGHT*4)/32
	lea rdi, [pixels]
	vmovdqu ymm0, ymmword ptr [zero64]
	_loop:
		vmovdqu ymmword ptr [rdi], ymm0
		add rdi, 32
		loop _loop
	ret
screen_clearPixelBuffer endp


endif
