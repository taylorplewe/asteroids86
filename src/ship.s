Ship struct
	x           dd     ?   ; 16.16 fixed point
	y           dd     ?   ; 16.16 fixed point
	rot         db     ?
	is_boosting db     ?
	velocity    Vector <?> ; 16.16 fixed point
Ship ends


.data

ship             Ship   {0}
ship_points      Point  5 dup ({0})
ship_fire_points Point  3 dup ({0})

ship_base_points      BasePoint {32, 0}, {16, 96}, {16, 160}, {11, 90}, {11, 166}
ship_fire_base_points BasePoint {28, 112}, {52, 128}, {28, 142}

; readonly
SHIP_VELOCITY_ACCEL = 00002800h ; 16.16 fixed point
SHIP_VELOCITY_MAX   = 00060000h ; 16.16 fixed point
SHIP_VELOCITY_DRAG  = 0000fa00h ; 16.16 fixed point


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
		jmp fireCheck
	@@:
	cmp [rdi].Keys.right, 0
	je @f
		add [ship].rot, 2
	@@:
	fireCheck:
	cmp [rdi].Keys.fire, 0
	je @f
		mov r8d, [ship_points].x
		shl r8d, 16
		mov r9d, [ship_points].y
		shl r9d, 16
		mov r10b, [ship].rot
		call bullets_createBullet
	@@:
	upDownCheck:
	xor al, al
	mov [ship].is_boosting, al
	cmp [rdi].Keys.up, 0
	je @f
		inc [ship].is_boosting
	
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
	; drag
	mov eax, [ship].velocity.x
	test eax, eax
	je @f
	cdqe
	imul rax, SHIP_VELOCITY_DRAG
	sar rax, 16
	mov [ship].velocity.x, eax
	@@:
	mov eax, [ship].velocity.y
	test eax, eax
	je moveEnd
	cdqe
	imul rax, SHIP_VELOCITY_DRAG
	sar rax, 16
	mov [ship].velocity.y, eax
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

	call ship_setAllPoints

	ret
ship_update endp

; in:
	; r8 - pointer to source BasePoint
	; r9 - pointer to destination Point
ship_setPoint proc
	xor rax, rax
	mov al, [r8].BasePoint.rad
	add al, [ship].rot
	mov bl, al
	; x
	mov al, bl
	call sin
	mov ecx, [r8].BasePoint.vec
	cdqe
	imul rax, rcx
	sar rax, 31
	mov ecx, eax
	mov eax, [ship].x
	shr eax, 16
	add eax, ecx
	mov [r9].Point.x, eax
	; y
	xor rax, rax ; clear upper bits
	mov al, bl
	call cos
	mov ecx, [r8].BasePoint.vec
	cdqe
	imul rax, rcx
	sar rax, 31
	mov ecx, eax
	mov eax, [ship].y
	shr eax, 16
	sub eax, ecx
	mov [r9].Point.y, eax

	ret
ship_setPoint endp

ship_setAllPoints proc
	xor rbx, rbx

	lea r8, ship_base_points
	lea r9, ship_points
	call ship_setPoint

	lea r8, ship_base_points + sizeof BasePoint
	lea r9, ship_points + sizeof Point
	call ship_setPoint

	lea r8, ship_base_points + sizeof BasePoint*2
	lea r9, ship_points + sizeof Point*2
	call ship_setPoint

	lea r8, ship_base_points + sizeof BasePoint*3
	lea r9, ship_points + sizeof Point*3
	call ship_setPoint

	lea r8, ship_base_points + sizeof BasePoint*4
	lea r9, ship_points + sizeof Point*4
	call ship_setPoint

	lea r8, ship_fire_base_points
	lea r9, ship_fire_points
	call ship_setPoint

	lea r8, ship_fire_base_points + sizeof BasePoint
	lea r9, ship_fire_points + sizeof Point
	call ship_setPoint

	lea r8, ship_fire_base_points + sizeof BasePoint*2
	lea r9, ship_fire_points + sizeof Point*2
	call ship_setPoint

	ret
ship_setAllPoints endp

ship_drawLine macro point1:req, point2:req
	mov eax, [point1].x
	mov [screen_point1].x, eax
	mov eax, [point1].y
	mov [screen_point1].y, eax
	mov eax, [point2].x
	mov [screen_point2].x, eax
	mov eax, [point2].y
	mov [screen_point2].y, eax
	; mov r8d, [ship_color]
	call screen_drawLine
endm

ship_draw proc
	mov r8d, [fg_color]

	ship_drawLine ship_points + sizeof Point*0, ship_points + sizeof Point*1
	ship_drawLine ship_points + sizeof Point*0, ship_points + sizeof Point*2
	ship_drawLine ship_points + sizeof Point*3, ship_points + sizeof Point*4

	mov al, [ship].is_boosting
	test al, al
	je @f
	mov rax, frame_counter
	and rax, 1b
	je @f
		ship_drawLine ship_fire_points + sizeof Point*0, ship_fire_points + sizeof Point*1
		ship_drawLine ship_fire_points + sizeof Point*1, ship_fire_points + sizeof Point*2
	@@:

	ret
ship_draw endp


; fire effect

.data

Fire struct
	is_alive         dd    ?
	p1               Point <?>
	p2               Point <?>
	num_frames_alive dd    ?
Fire ends
fires Fire 64 dup (<?>)

fire_update proc
	ret
fire_update endp