Ship struct
	x      dd ?
	y      dd ?
	rot    db ?
Ship ends

.data

ship Ship <?>
ship_points Point 3 dup (<?>)

BasePoint struct
	vec dd ?
	rad db ? ; 256-based radians; 256 = 360 degrees
BasePoint ends
ship_base_points BasePoint {64, 0}, {32, 96}, {32, 160}

; readonly
ship_color Pixel <0ffh, 0ffh, 0ffh, 0ffh>


.code

ship_init proc
	mov [ship].x, SCREEN_WIDTH/2
	mov [ship].y, SCREEN_HEIGHT/2
	ret
ship_init endp

; in:
	; rdi - pointer to keys_down: Keys struct
ship_update proc
	cmp [rdi].Keys.left, 0
	je @f
		dec [ship].rot
		jmp upDownCheck
	@@:
	cmp [rdi].Keys.right, 0
	je @f
		inc [ship].rot
	@@:
	upDownCheck:
	cmp [rdi].Keys.up, 0
	je @f
		dec [ship].y
		jmp moveEnd
	@@:
	cmp [rdi].Keys.down, 0
	je @f
		inc [ship].y
	@@:
	moveEnd:

	call ship_setPoints

	ret
ship_update endp

ship_setPoints proc
	mov al, [ship_base_points].rad
	add al, [ship].rot
	mov bl, al
	; x
	mov al, bl
	call sin
	mov ecx, [ship_base_points].vec
	cdqe
	imul rax, rcx
	sar rax, 31
	add eax, [ship].x
	mov [ship_points].x, eax
	; y
	xor rax, rax ; clear upper bits
	mov al, bl
	call cos
	mov ecx, [ship_base_points].vec
	; good here
	cdqe
	imul rax, rcx
	sar rax, 31
	mov ecx, eax
	mov eax, [ship].y
	sub eax, ecx
	mov [ship_points].y, eax

	xor rax, rax
	mov al, [ship_base_points + sizeof BasePoint].rad
	add al, [ship].rot
	mov bl, al
	; x
	mov al, bl
	call sin
	mov ecx, [ship_base_points + sizeof BasePoint].vec
	cdqe
	imul rax, rcx
	sar rax, 31
	add eax, [ship].x
	mov [ship_points + sizeof Point].x, eax
	; y
	xor rax, rax ; clear upper bits
	mov al, bl
	call cos
	mov ecx, [ship_base_points + sizeof BasePoint].vec
	; good here
	cdqe
	imul rax, rcx
	sar rax, 31
	mov ecx, eax
	mov eax, [ship].y
	sub eax, ecx
	mov [ship_points + sizeof Point].y, eax

	xor rax, rax
	mov al, [ship_base_points + (sizeof BasePoint)*2].rad
	add al, [ship].rot
	mov bl, al
	; x
	mov al, bl
	call sin
	mov ecx, [ship_base_points + (sizeof BasePoint)*2].vec
	cdqe
	imul rax, rcx
	sar rax, 31
	add eax, [ship].x
	mov [ship_points + (sizeof Point)*2].x, eax
	; y
	xor rax, rax ; clear upper bits
	mov al, bl
	call cos
	mov ecx, [ship_base_points + (sizeof BasePoint)*2].vec
	cdqe
	imul rax, rcx
	sar rax, 31
	mov ecx, eax
	mov eax, [ship].y
	sub eax, ecx
	mov [ship_points + (sizeof Point)*2].y, eax

	ret
ship_setPoints endp

ship_draw proc
	mov eax, [ship_points].x
	mov [screen_point1].x, eax
	mov eax, [ship_points].y
	mov [screen_point1].y, eax
	mov eax, [ship_points + sizeof Point].x
	mov [screen_point2].x, eax
	mov eax, [ship_points + sizeof Point].y
	mov [screen_point2].y, eax
	mov r8d, [ship_color]
	call screen_drawLine

	mov eax, [ship_points + sizeof Point].x
	mov [screen_point1].x, eax
	mov eax, [ship_points + sizeof Point].y
	mov [screen_point1].y, eax
	mov eax, [ship_points + sizeof Point * 2].x
	mov [screen_point2].x, eax
	mov eax, [ship_points + sizeof Point * 2].y
	mov [screen_point2].y, eax
	mov r8d, [ship_color]
	call screen_drawLine

	mov eax, [ship_points + sizeof Point * 2].x
	mov [screen_point1].x, eax
	mov eax, [ship_points + sizeof Point * 2].y
	mov [screen_point1].y, eax
	mov eax, [ship_points].x
	mov [screen_point2].x, eax
	mov eax, [ship_points].y
	mov [screen_point2].y, eax
	mov r8d, [ship_color]
	call screen_drawLine

	ret
ship_draw endp