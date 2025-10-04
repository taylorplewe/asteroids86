.data

pixels        Pixel SCREEN_WIDTH*SCREEN_HEIGHT dup (<?>)
screen_point1 Point <?>
screen_point2 Point <?>
x_diff        dd ?
y_diff        dd ?
x_add         dd ?
y_add         dd ?
is_xdiff_neg  db ?
is_ydiff_neg  db ?


.code

; TODO: convert statically allocated bss variables to stack variables
; in:
	; point1
	; point2
screen_drawLine proc
	xor al, al
	mov byte ptr [is_xdiff_neg], al
	mov byte ptr [is_ydiff_neg], al

	mov eax, [screen_point2].Point.x
	sub eax, [screen_point1].Point.x
	mov ebx, eax
	shl ebx, 1
	rcl byte ptr [is_xdiff_neg], 1
	abseax
	mov dword ptr [x_diff], eax
	
	mov eax, [screen_point2].Point.y
	sub eax, [screen_point1].Point.y
	mov ebx, eax
	shl ebx, 1
	rcl byte ptr [is_ydiff_neg], 1
	abseax
	mov dword ptr [y_diff], eax

	cmp eax, dword ptr [x_diff]
	jl xDiffGreater

	;yDiffGreater:
	xDiffGreater:	
	

	ret
screen_drawLine endp
