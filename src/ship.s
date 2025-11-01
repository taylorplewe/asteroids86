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
	respawn_counter  dd     ?
	velocity         Vector <?> ; 16.16 fixed point
Ship ends

SHIP_RESPAWN_COUNTER   = 60 * 4
SHIP_VELOCITY_ACCEL    = 00005000h ; 16.16 fixed point
SHIP_VELOCITY_MAX      = 00080000h ; 16.16 fixed point
SHIP_VELOCITY_DRAG     = 0000fa00h ; 16.16 fixed point
SHIP_VELOCITY_KICK     = 00008000h ; 16.16 fixed point
SHIP_RADIUS            = 40
SHIP_R_SQ              = SHIP_RADIUS * SHIP_RADIUS
SHIP_NUM_FLASHES       = 8
SHIP_FLASH_COUNTER_AMT = 9


.data

ship_base_points BasePoint {32, 0}, {16, 96}, {16, 160}, {11, 90}, {11, 166}
SHIP_NUM_POINTS = ($ - ship_base_points) / sizeof BasePoint

.data?

ship                  Ship  <>
ship_points           Point SHIP_NUM_POINTS dup (<>)
ship_color            Pixel <>
ship_num_flashes_left dd    ?
ship_flash_counter    dd    ?


.code

ship_respawn proc
	mov [ship].x, SCREEN_WIDTH/2 shl 16
	mov [ship].y, SCREEN_HEIGHT/2 shl 16
	xor eax, eax
	mov [ship].rot, al
	mov [ship].velocity.x, eax
	mov [ship].velocity.y, eax
	mov [ship].respawn_counter, 0
	mov [ship].is_boosting, 0
	mov [ship_num_flashes_left], SHIP_NUM_FLASHES
	mov [ship_flash_counter], SHIP_FLASH_COUNTER_AMT

	ret
ship_respawn endp

; in:
	; rdi - pointer to keys_down: Keys struct
ship_update proc
	cmp [ship].respawn_counter, 0
	je normalUpdate
		dec [ship].respawn_counter
		jne @f
		call ship_respawn
		lea r8, ship_base_points
		lea r9, ship_points
		call ship_setAllPoints
		@@:
		ret
	normalUpdate:
	cmp [rdi].Keys.left, 0
	je @f
		sub [ship].rot, 3
		jmp fireCheck
	@@:
	cmp [rdi].Keys.right, 0
	je @f
		add [ship].rot, 3
	@@:

	fireCheck:
	cmp [rdi].Keys.fire, 0
	je @f
		mov r8d, [ship_points].x
		shl r8d, 16
		mov r9d, [ship_points].y
		shl r9d, 16
		mov r10b, [ship].rot
		xor r11d, r11d ; not evil
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

	lea r8, ship_base_points
	lea r9, ship_points
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

	; flash (invincibility)
	cmp [ship_num_flashes_left], 0
	je flashEnd
	dec [ship_flash_counter]
	jne flashEnd
		mov [ship_flash_counter], SHIP_FLASH_COUNTER_AMT
		dec [ship_num_flashes_left]
		bt [ship_num_flashes_left], 0
		jc @f
			mov eax, [fg_color]
			jmp flashColStore
		@@:
			mov eax, [dim_color]
		flashColStore:
		mov [ship_color], eax
	flashEnd:

	call ship_checkBullets

	ret
ship_update endp

; in:
	; r8 - pointer to first source BasePoint
	; r9 - pointer to first destination Point
	; TODO: I meant to make this method callable from game.s but I think I went back on that. can be refactored
ship_setAllPoints proc
	push rbx
	push r10
	push r11
	push r12

	mov r11b, [ship].rot
	lea r10, ship
	mov r12d, 00010000h

	call applyBasePointToPoint

	repeat 4
	add r8, sizeof BasePoint
	add r9, sizeof Point
	call applyBasePointToPoint
	endm

	pop r12
	pop r11
	pop r10
	pop rbx
	ret
ship_setAllPoints endp

ship_destroy proc
	push rbx
	push rcx
	push rdx
	push r8

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

	dec [lives]
	cmp [lives], 0
	je gameover
		mov [ship].respawn_counter, SHIP_RESPAWN_COUNTER
		jmp _end
	gameover:
		mov eax, GAMEOVER_TIMER_AMT
		mov [gameover_timer], eax
		inc [is_in_gameover]
	_end:
	pop r8
	pop rdx
	pop rcx
	pop rbx
	ret
ship_destroy endp

ship_checkBullets proc
	push rbx
	push rcx
	push rsi
	push r8
	push r9

	cmp [ship_num_flashes_left], 0
	jne noHit

	mov eax, [bullets_arr].Array.data.len
	test eax, eax
	je _end
	xor ecx, ecx
	lea rsi, bullets
	mainLoop:
		cmp [rsi].Bullet.is_evil, 0
		je next

		; check if bullet is inside this ship's circular hitbox, dictacted by it's 'mass'
		; hit if (dx^2 + dy^2) <= r^2
		xor eax, eax ; clear upper bits
		mov ax, word ptr [rsi].Bullet.pos.x + 2
		sub ax, word ptr [ship].x + 2
		cwde
		imul eax, eax
		mov r8d, eax
		mov ax, word ptr [rsi].Bullet.pos.y + 2
		sub ax, word ptr [ship].y + 2
		cwde
		imul eax, eax
		mov r9d, eax

		add r8d, r9d
		cmp r8d, SHIP_R_SQ
		jg next

		; hit!
		push rsi
		lea rsi, bullets_arr
		mov eax, ecx
		call array_removeAt
		pop rsi
		call ship_destroy
		mov eax, 1
		jmp _end

		next:
		add rsi, sizeof Bullet
		inc ecx
		cmp ecx, [bullets_arr].Array.data.len
		jb mainLoop

	noHit:
	xor eax, eax

	_end:
	pop r9
	pop r8
	pop rsi
	pop rcx
	pop rbx
	ret
ship_checkBullets endp


ship_draw proc
	cmp [ship].respawn_counter, 0
	jne _end
	mov r8d, [ship_color]

	screen_mDrawLine ship_points + sizeof Point*0, ship_points + sizeof Point*1
	screen_mDrawLine ship_points + sizeof Point*0, ship_points + sizeof Point*2
	screen_mDrawLine ship_points + sizeof Point*3, ship_points + sizeof Point*4

	_end:
	ret
ship_draw endp


endif
