Ship struct
	x      dd ?
	y      dd ?
	rot    dd ?
Ship ends

.data

ship Ship <?>
ship_points Point 3 dup (<?>)

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
	SHIP_RADIUS = 64
	; ship is a triangle

	; forward-facing point
	mov eax, [ship].Ship.x
	mov [ship_points].Point.x, eax
	mov eax, [ship].Ship.y
	sub eax, SHIP_RADIUS
	mov [ship_points].Point.y, eax

	; left-rear point
	mov eax, [ship].Ship.x
	sub eax, SHIP_RADIUS/2
	mov [ship_points + sizeof Point].Point.x, eax
	mov eax, [ship].Ship.y
	add eax, SHIP_RADIUS/2
	mov [ship_points + sizeof Point].Point.y, eax

	; right-rear point
	mov eax, [ship].Ship.x
	add eax, SHIP_RADIUS/2
	mov [ship_points + (sizeof Point)*2].Point.x, eax
	mov eax, [ship].Ship.y
	add eax, SHIP_RADIUS/2
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