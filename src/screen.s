ifndef screen_h
screen_h = 1

include <globaldefs.inc>


.data

pixels        Pixel SCREEN_WIDTH*SCREEN_HEIGHT dup (<?>)
screen_point1 Point <?>
screen_point2 Point <?>
x_diff        dd ?
y_diff        dd ?
x_add         dd ? ; 16.16 fixed point
y_add         dd ? ; 16.16 fixed point
is_xdiff_neg  db ?
is_ydiff_neg  db ?


.code

; in:
	; ebx  - x
	; ecx  - y
	; r8d  - color
	; rdi  - point to pixels
	; r14d - SCREEN_WIDTH
	; r15d - SCREEN_HEIGHT
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
endm

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

; in:
	; ebx - x
	; ecx - y
	; r8d - color
	; rdi - point to pixels
	; r14d - SCREEN_WIDTH
	; r15d - SCREEN_HEIGHT
screen_drawCircle macro
	push rbp
	mov rbp, rsp
	sub rsp, 16

	push rdx

	CIRCLE_RADIUS = 4
	CIRCLE_RSQ    = CIRCLE_RADIUS * CIRCLE_RADIUS

	mov dword ptr [rsp + 8], ebx
	mov dword ptr [rsp + 12], ecx
	sub ebx, CIRCLE_RADIUS
	sub ecx, CIRCLE_RADIUS

	mov dword ptr [rsp + 4], CIRCLE_RADIUS*2
	rowLoop:
		mov dword ptr [rsp], CIRCLE_RADIUS*2
		colLoop:
			; inside circle if (dx^2 + dy^2) <= r^2
			mov eax, ebx
			sub eax, dword ptr [rsp + 8]
			imul eax, eax
			mov edx, ecx
			sub edx, dword ptr [rsp + 12]
			imul edx, edx
			add eax, edx
			cmp eax, CIRCLE_RSQ
			jg colLoopNext

			push rdx
			screen_setPixelWrapped
			pop rdx

			colLoopNext:
			inc ebx
			dec dword ptr [rsp]
			jne colLoop
		rowLoopNext:
		sub ebx, CIRCLE_RADIUS*2
		inc ecx
		dec dword ptr [rsp + 4]
		jne rowLoop

	pop rdx

	mov rsp, rbp
	pop rbp
endm

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

zero64 db 64 dup (0)
screen_clearPixelBuffer proc
	rdtsc
	mov r8d, edx
	shl r8, 32
	or r8, rax
	mov ecx, (SCREEN_WIDTH*SCREEN_HEIGHT*4)/32
	; mov ecx, (SCREEN_WIDTH*SCREEN_HEIGHT)/2
	lea rdi, [pixels]
	vmovdqu ymm0, ymmword ptr [zero64]
	; mov rax, 0
	_loop:
		vmovdqu ymmword ptr [rdi], ymm0
		; mov qword ptr [rdi], rax
		add rdi, 32
		; add rdi, 8
		loop _loop

	rdtsc
	shl rdx, 32
	or rdx, rax
	sub rdx, r8

	ret
screen_clearPixelBuffer endp


endif
