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

screen_plotPoint macro
	mov dword ptr [rdi], r8d

	mov rsi, rdi
	sub rsi, SCREEN_WIDTH * sizeof Pixel
	cmp rsi, r12
	jb @f
	mov dword ptr [rsi], r8d
	@@:

	mov rsi, rdi
	add rsi, SCREEN_WIDTH * sizeof Pixel
	cmp rsi, r13
	ja @f
	mov dword ptr [rsi], r8d
	@@:

	mov dword ptr [rdi + sizeof Pixel], r8d
	mov dword ptr [rdi - sizeof Pixel], r8d
endm

; TODO: convert statically allocated bss variables to stack variables
; in:
	; r8d - color to draw
	; point1
	; point2
screen_drawLine proc
	xor al, al
	mov byte ptr [is_xdiff_neg], al
	mov byte ptr [is_ydiff_neg], al

	; rdi = pointer into pixels
	lea rdi, pixels
	lea r12, pixels
	lea r13, pixels + SCREEN_WIDTH * SCREEN_HEIGHT * sizeof Pixel
	
	mov eax, [screen_point1].y
	imul eax, SCREEN_WIDTH * sizeof Pixel
	add rdi, rax
	mov eax, [screen_point1].x
	shl eax, 2 ; imul sizeof Pixel
	add rdi, rax

	; x_diff = |p2.x - p1.x|
	mov eax, [screen_point2].x
	sub eax, [screen_point1].x
	mov ebx, eax
	shl ebx, 1
	rcl byte ptr [is_xdiff_neg], 1
	abseax
	mov dword ptr [x_diff], eax
	
	; y_diff = |p2.y - p1.y|
	mov eax, [screen_point2].y
	sub eax, [screen_point1].y
	mov ebx, eax
	shl ebx, 1
	rcl byte ptr [is_ydiff_neg], 1
	abseax
	mov dword ptr [y_diff], eax

	cmp eax, dword ptr [x_diff]
	jl xDiffGreater
	yDiffGreater:
		; x_add = x_diff / y_diff
		mov eax, dword ptr [x_diff]
		shl eax, 16
		cdq
		mov ebx, dword ptr [y_diff]
		idiv ebx
		mov dword ptr [x_add], eax

		mov ecx, dword ptr [y_diff]
		mov eax, 00008000h ; 0.5 fixed point
		cmp byte ptr [is_ydiff_neg], 0
		je yIncLoop
		yDecLoop:
			cmp byte ptr [is_xdiff_neg], 0
			je yDecXIncLoop
			yDecXDecLoop:
				screen_plotPoint
				sub rdi, SCREEN_WIDTH * sizeof Pixel

				add eax, dword ptr [x_add]
				cmp eax, 00010000h
				jl @f
				sub rdi, sizeof Pixel
				and eax, 0000ffffh
				@@:

				loop yDecXDecLoop
			ret
			yDecXIncLoop:
				screen_plotPoint
				sub rdi, SCREEN_WIDTH * sizeof Pixel

				add eax, dword ptr [x_add]
				cmp eax, 00010000h
				jl @f
				add rdi, sizeof Pixel
				and eax, 0000ffffh
				@@:

				loop yDecXIncLoop
			ret
		yIncLoop:
			cmp byte ptr [is_xdiff_neg], 0
			je yIncXIncLoop
			yIncXDecLoop:
				screen_plotPoint
				add rdi, SCREEN_WIDTH * sizeof Pixel

				add eax, dword ptr [x_add]
				cmp eax, 00010000h
				jl @f
				sub rdi, sizeof Pixel
				and eax, 0000ffffh
				@@:

				loop yIncXDecLoop
			ret
			yIncXIncLoop:
				screen_plotPoint
				add rdi, SCREEN_WIDTH * sizeof Pixel

				add eax, dword ptr [x_add]
				cmp eax, 00010000h
				jl @f
				add rdi, sizeof Pixel
				and eax, 0000ffffh
				@@:

				loop yIncXIncLoop
			ret
	xDiffGreater:	
		; x_add = x_diff / y_diff
		mov eax, dword ptr [y_diff]
		shl eax, 16
		cdq
		mov ebx, dword ptr [x_diff]
		idiv ebx
		mov dword ptr [y_add], eax

		mov ecx, dword ptr [x_diff]
		mov eax, 00008000h ; 0.5 fixed point
		cmp byte ptr [is_xdiff_neg], 0
		je xIncLoop
		xDecLoop:
			cmp byte ptr [is_ydiff_neg], 0
			je xDecYIncLoop
			xDecYDecLoop:
				screen_plotPoint
				sub rdi, sizeof Pixel

				add eax, dword ptr [y_add]
				cmp eax, 00010000h
				jl @f
				sub rdi, SCREEN_WIDTH * sizeof Pixel
				and eax, 0000ffffh
				@@:

				loop xDecYDecLoop
			ret
			xDecYIncLoop:
				screen_plotPoint
				sub rdi, sizeof Pixel

				add eax, dword ptr [y_add]
				cmp eax, 00010000h
				jl @f
				add rdi, SCREEN_WIDTH * sizeof Pixel
				and eax, 0000ffffh
				@@:

				loop xDecYIncLoop
			ret
		xIncLoop:
			cmp byte ptr [is_ydiff_neg], 0
			je xIncYIncLoop
			xIncYDecLoop:
				screen_plotPoint
				add rdi, sizeof Pixel

				add eax, dword ptr [y_add]
				cmp eax, 00010000h
				jl @f
				sub rdi, SCREEN_WIDTH * sizeof Pixel
				and eax, 0000ffffh
				@@:

				loop xIncYDecLoop
			ret
			xIncYIncLoop:
				screen_plotPoint
				add rdi, sizeof Pixel

				add eax, dword ptr [y_add]
				cmp eax, 00010000h
				jl @f
				add rdi, SCREEN_WIDTH * sizeof Pixel
				and eax, 0000ffffh
				@@:

				loop xIncYIncLoop
			ret
	
	ret
screen_drawLine endp

; in:
	; point1
	; r8d - color
screen_drawPoint proc
	; rdi = pointer into pixels
	lea rdi, pixels
	mov eax, [screen_point1].y
	imul eax, SCREEN_WIDTH * sizeof Pixel
	add rdi, rax
	mov eax, [screen_point1].x
	shl eax, 2 ; imul sizeof Pixel
	add rdi, rax

	screen_plotPoint

	ret
screen_drawPoint endp
