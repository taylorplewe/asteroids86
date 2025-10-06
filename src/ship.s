Ship struct
	x        dd ?     ; 16.16 fixed point
	y        dd ?     ; 16.16 fixed point
	rot      db ?
	velocity Vector <?> ; 16.16 fixed point
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
SHIP_VELOCITY_ACCEL = 00000600h ; 16.16 fixed point
SHIP_VELOCITY_MAX   = 00020000h ; 16.16 fixed point


.code

ship_init proc
	mov [ship].x, SCREEN_WIDTH/2 shl 16
	mov [ship].y, SCREEN_HEIGHT/2 shl 16
	xor eax, eax
	mov [ship].rot, al
	mov [ship].velocity.x, eax
	mov [ship].velocity.y, eax

	ret
ship_init endp

; in:
	; rdi - pointer to keys_down: Keys struct
ship_update proc
	cmp [rdi].Keys.left, 0
	je @f
		sub [ship].rot, 2
		jmp upDownCheck
	@@:
	cmp [rdi].Keys.right, 0
	je @f
		add [ship].rot, 2
	@@:
	upDownCheck:
	cmp [rdi].Keys.up, 0
	je @f
		xor rax, rax
		mov al, [ship].rot
		call sin
		cdqe
		imul rax, SHIP_VELOCITY_ACCEL
		sar rax, 31
		add [ship].velocity.x, eax

		xor rax, rax
		mov al, [ship].rot
		call cos
		cdqe
		imul rax, SHIP_VELOCITY_ACCEL
		sar rax, 31
		sub [ship].velocity.y, eax
		
		jmp moveEnd
	@@:
	cmp [rdi].Keys.down, 0
	je @f
		inc [ship].y
	@@:
	moveEnd:

	; velocity bounds check
	mov eax, [ship].velocity.x
	cmp eax, SHIP_VELOCITY_MAX
	jg xVelocitySetMax
	cmp eax, -SHIP_VELOCITY_MAX
	jg yVeloCheck
	;xVelocitySetMin:
		mov [ship].velocity.x, -SHIP_VELOCITY_MAX
		jmp yVeloCheck
	xVelocitySetMax:
		mov [ship].velocity.x, SHIP_VELOCITY_MAX
	yVeloCheck:

	mov eax, [ship].velocity.y
	cmp eax, SHIP_VELOCITY_MAX
	jg yVelocitySetMax
	cmp eax, -SHIP_VELOCITY_MAX
	jg yVeloCheckEnd
	;yVelocitySetMin:
		mov [ship].velocity.y, -SHIP_VELOCITY_MAX
		jmp yVeloCheckEnd
	yVelocitySetMax:
		mov [ship].velocity.y, SHIP_VELOCITY_MAX
	yVeloCheckEnd:

	; add velocity to position
	mov eax, [ship].velocity.x
	add [ship].x, eax
	mov eax, [ship].velocity.y
	add [ship].y, eax

	call ship_setPoints

	ret
ship_update endp

ship_setPoints proc
	xor rax, rax
	xor rbx, rbx
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
	mov ecx, eax
	mov eax, [ship].x
	shr eax, 16
	add eax, ecx
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
	shr eax, 16
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
	mov ecx, eax
	mov eax, [ship].x
	shr eax, 16
	add eax, ecx
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
	shr eax, 16
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
	mov ecx, eax
	mov eax, [ship].x
	shr eax, 16
	add eax, ecx
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
	shr eax, 16
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