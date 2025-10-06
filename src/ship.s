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
	mov [ship].Ship.x, SCREEN_WIDTH/2
	mov [ship].Ship.y, SCREEN_HEIGHT/2
	ret
ship_init endp

; in:
	; rdi - pointer to keys_down: Keys struct
ship_update proc
	cmp [rdi].Keys.left, 0
	je @f
		dec [ship].Ship.rot
		jmp upDownCheck
	@@:
	cmp [rdi].Keys.right, 0
	je @f
		inc [ship].Ship.rot
	@@:
	upDownCheck:
	cmp [rdi].Keys.up, 0
	je @f
		dec [ship].Ship.y
		jmp moveEnd
	@@:
	cmp [rdi].Keys.down, 0
	je @f
		inc [ship].Ship.y
	@@:
	moveEnd:

	call ship_setPoints

	ret
ship_update endp

ship_setPoints proc
	mov al, [ship_base_points].BasePoint.rad
	add al, [ship].Ship.rot
	mov bl, al
	; x
	mov al, bl
	call sin
	mov ecx, [ship_base_points].BasePoint.vec
	cdqe
	imul rax, rcx
	sar rax, 31
	add eax, [ship].Ship.x
	mov [ship_points].Point.x, eax
	; y
	xor rax, rax ; clear upper bits
	mov al, bl
	call cos
	mov ecx, [ship_base_points].BasePoint.vec
	; good here
	cdqe
	imul rax, rcx
	sar rax, 31
	mov ecx, eax
	mov eax, [ship].Ship.y
	sub eax, ecx
	mov [ship_points].Point.y, eax

	xor rax, rax
	mov al, [ship_base_points + sizeof BasePoint].BasePoint.rad
	add al, [ship].Ship.rot
	mov bl, al
	; x
	mov al, bl
	call sin
	mov ecx, [ship_base_points + sizeof BasePoint].BasePoint.vec
	cdqe
	imul rax, rcx
	sar rax, 31
	add eax, [ship].Ship.x
	mov [ship_points + sizeof Point].Point.x, eax
	; y
	xor rax, rax ; clear upper bits
	mov al, bl
	call cos
	mov ecx, [ship_base_points + sizeof BasePoint].BasePoint.vec
	; good here
	cdqe
	imul rax, rcx
	sar rax, 31
	mov ecx, eax
	mov eax, [ship].Ship.y
	sub eax, ecx
	mov [ship_points + sizeof Point].Point.y, eax

	xor rax, rax
	mov al, [ship_base_points + (sizeof BasePoint)*2].BasePoint.rad
	add al, [ship].Ship.rot
	mov bl, al
	; x
	mov al, bl
	call sin
	mov ecx, [ship_base_points + (sizeof BasePoint)*2].BasePoint.vec
	cdqe
	imul rax, rcx
	sar rax, 31
	add eax, [ship].Ship.x
	mov [ship_points + (sizeof Point)*2].Point.x, eax
	; y
	xor rax, rax ; clear upper bits
	mov al, bl
	call cos
	mov ecx, [ship_base_points + (sizeof BasePoint)*2].BasePoint.vec
	cdqe
	imul rax, rcx
	sar rax, 31
	mov ecx, eax
	mov eax, [ship].Ship.y
	sub eax, ecx
	mov [ship_points + (sizeof Point)*2].Point.y, eax

	ret
ship_setPoints endp

; in:
	; rdi - pointer to pixel buffer
ship_draw proc
	; mov eax, [ship].Ship.y
	; imul eax, SCREEN_WIDTH * sizeof Pixel
	; mov ebx, [ship].Ship.x
	; shl ebx, 2 ; imul sizeof Pixel
	; add eax, ebx

	; mov ebx, [ship_color]
	; mov dword ptr [rdi + rax], ebx

	mov eax, [ship_points].Point.x
	mov [screen_point1].Point.x, eax
	mov eax, [ship_points].Point.y
	mov [screen_point1].Point.y, eax
	mov eax, [ship_points + sizeof Point].Point.x
	mov [screen_point2].Point.x, eax
	mov eax, [ship_points + sizeof Point].Point.y
	mov [screen_point2].Point.y, eax
	mov r8d, [ship_color]
	call screen_drawLine

	mov eax, [ship_points + sizeof Point].Point.x
	mov [screen_point1].Point.x, eax
	mov eax, [ship_points + sizeof Point].Point.y
	mov [screen_point1].Point.y, eax
	mov eax, [ship_points + sizeof Point * 2].Point.x
	mov [screen_point2].Point.x, eax
	mov eax, [ship_points + sizeof Point * 2].Point.y
	mov [screen_point2].Point.y, eax
	mov r8d, [ship_color]
	call screen_drawLine

	mov eax, [ship_points + sizeof Point * 2].Point.x
	mov [screen_point1].Point.x, eax
	mov eax, [ship_points + sizeof Point * 2].Point.y
	mov [screen_point1].Point.y, eax
	mov eax, [ship_points].Point.x
	mov [screen_point2].Point.x, eax
	mov eax, [ship_points].Point.y
	mov [screen_point2].Point.y, eax
	mov r8d, [ship_color]
	call screen_drawLine

	ret
ship_draw endp