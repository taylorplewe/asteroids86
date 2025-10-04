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

ship_update proc
	call ship_setPoints

	inc [ship].Ship.x

	ret
ship_update endp

ship_setPoints proc
	SHIP_RADIUS = 32
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
	mov eax, [ship].Ship.y
	imul eax, SCREEN_WIDTH * sizeof Pixel
	mov ebx, [ship].Ship.x
	shl ebx, 2 ; imul sizeof Pixel
	add eax, ebx

	mov ebx, [ship_color]
	mov dword ptr [rdi + rax], ebx

	ret
ship_draw endp