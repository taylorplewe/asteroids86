ifndef ship_h
ship_h = 1

include <globaldefs.inc>

include <fx\fire.s>
include <fx\ship-shard.s>
include <bullet.s>
include <screen.s>


Ship struct
	x                dd     ?   ; 16.16 fixed point
	y                dd     ?   ; 16.16 fixed point
	rot              db     ?
	is_boosting      db     ?
	ticks_to_respawn dd     ?
	velocity         Vector <?> ; 16.16 fixed point
Ship ends

SHIP_TICKS_TO_RESPAWN = 60 * 4


.data

ship             Ship   {0}
ship_points      Point  5 dup ({0})

ship_base_points      BasePoint {32, 0}, {16, 96}, {16, 160}, {11, 90}, {11, 166}

; readonly
SHIP_VELOCITY_ACCEL = 00005000h ; 16.16 fixed point
SHIP_VELOCITY_MAX   = 00080000h ; 16.16 fixed point
SHIP_VELOCITY_DRAG  = 0000fa00h ; 16.16 fixed point
SHIP_VELOCITY_KICK  = 00008000h ; 16.16 fixed point


.code

ship_respawn proc
	mov [ship].x, SCREEN_WIDTH/2 shl 16
	mov [ship].y, SCREEN_HEIGHT/2 shl 16
	xor eax, eax
	mov [ship].rot, al
	mov [ship].velocity.x, eax
	mov [ship].velocity.y, eax

	ret
ship_respawn endp

; in:
	; rdi - pointer to keys_down: Keys struct
ship_update proc
	cmp [ship].ticks_to_respawn, 0
	je normalUpdate
		dec [ship].ticks_to_respawn
		jne @f
		call ship_respawn
		call ship_setAllPoints
		@@:
		ret
	normalUpdate:
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
		push rdi
		call bullet_create
		pop rdi

		; kick
		xor rax, rax
		mov al, [ship].rot
		add al, 128
		mov bl, al
		call sin
		cdqe
		imul rax, SHIP_VELOCITY_KICK
		sar rax, 31
		add [ship].velocity.x, eax
		xor rax, rax
		mov al, bl
		call cos
		cdqe
		imul rax, SHIP_VELOCITY_KICK
		sar rax, 31
		sub [ship].velocity.y, eax

	@@:

	; boost
	mov [ship].is_boosting, 0
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
	je @f
		cdqe
		imul rax, SHIP_VELOCITY_DRAG
		sar rax, 16
		mov [ship].velocity.y, eax
	@@:

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

	; wrap position
	lea rsi, ship
	call wrapPointAroundScreen

	call ship_setAllPoints

	; draw fire lines
	cmp [ship].is_boosting, 0
	je @f
	mov rax, [frame_counter]
	and rax, 1b
	jne @f
	mov rax, 0000ffff0000ffffh 
	mov r8, qword ptr [ship_points + 3 * sizeof Point]
	and r8, rax
	shl r8, 16
	mov r10, qword ptr [ship_points + 4 * sizeof Point]
	and r10, rax
	shl r10, 16
	xor ebx, ebx
	mov bl, [ship].rot
	add bl, 128
	call fire_create
	@@:

	ret
ship_update endp

ship_setAllPoints proc
	xor rbx, rbx

	mov r11b, [ship].rot
	lea r10, ship
	mov r12d, 00010000h

	lea r8, ship_base_points
	lea r9, ship_points
	call applyBasePointToPoint

	lea r8, ship_base_points + sizeof BasePoint
	lea r9, ship_points + sizeof Point
	call applyBasePointToPoint

	lea r8, ship_base_points + sizeof BasePoint*2
	lea r9, ship_points + sizeof Point*2
	call applyBasePointToPoint

	lea r8, ship_base_points + sizeof BasePoint*3
	lea r9, ship_points + sizeof Point*3
	call applyBasePointToPoint

	lea r8, ship_base_points + sizeof BasePoint*4
	lea r9, ship_points + sizeof Point*4
	call applyBasePointToPoint

	ret
ship_setAllPoints endp

ship_destroy proc
	push rbx
	push rcx
	push rdx
	push r8

	mov [ship].ticks_to_respawn, SHIP_TICKS_TO_RESPAWN

	mov rbx, qword ptr [ship]
	mov rcx, qword ptr [ship].velocity
	mov edx, 36
	mov r8b, [ship].rot
	call shipShard_create

	mov rbx, qword ptr [ship]
	mov rcx, qword ptr [ship].velocity
	mov edx, 16
	add r8b, 256/5
	call shipShard_create

	mov rbx, qword ptr [ship]
	mov rcx, qword ptr [ship].velocity
	mov edx, 25
	add r8b, 256/5
	call shipShard_create

	mov rbx, qword ptr [ship]
	mov rcx, qword ptr [ship].velocity
	mov edx, 12
	add r8b, 256/5
	call shipShard_create

	mov rbx, qword ptr [ship]
	mov rcx, qword ptr [ship].velocity
	mov edx, 20
	add r8b, 256/5
	call shipShard_create

	pop r8
	pop rdx
	pop rcx
	pop rbx
	ret
ship_destroy endp

ship_draw proc
	cmp [ship].ticks_to_respawn, 0
	jne _end
	mov r8d, [fg_color]

	screen_mDrawLine ship_points + sizeof Point*0, ship_points + sizeof Point*1
	screen_mDrawLine ship_points + sizeof Point*0, ship_points + sizeof Point*2
	screen_mDrawLine ship_points + sizeof Point*3, ship_points + sizeof Point*4

	_end:
	ret
ship_draw endp


endif
