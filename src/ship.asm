%ifndef ship_h
%define ship_h

%include "src/globaldefs.inc"

%include "src/data/shrink-vals.inc"
%include "src/fx/fire.asm"
%include "src/fx/ship-shard.asm"
%include "src/bullet.asm"
%include "src/screen.asm"


struc Ship
	.x:               resd 1   ; 16.16 fixed point
	.y:               resd 1   ; 16.16 fixed point
	.rot:             resb 1
	.is_boosting:     resb 1
	.respawn_counter: resd 1
	.velocity:        resb Vector_size ; 16.16 fixed point
endstruc

SHIP_RESPAWN_COUNTER   equ 60 * 4
SHIP_VELOCITY_ACCEL    equ 00005000h ; 16.16 fixed point
SHIP_VELOCITY_MAX      equ 00080000h ; 16.16 fixed point
SHIP_VELOCITY_DRAG     equ 0000fa00h ; 16.16 fixed point
SHIP_VELOCITY_KICK     equ 00008000h ; 16.16 fixed point
SHIP_RADIUS            equ 40
SHIP_R_SQ              equ SHIP_RADIUS * SHIP_RADIUS
SHIP_NUM_FLASHES       equ 8
SHIP_FLASH_COUNTER_AMT equ 9


section .data

ship_base_points:
	istruc BasePoint
		at .vec, dd 32
		at .rad, db 0
	iend
	istruc BasePoint
		at .vec, dd 16
		at .rad, db 96
	iend
	istruc BasePoint
		at .vec, dd 16
		at .rad, db 160
	iend
	istruc BasePoint
		at .vec, dd 11
		at .rad, db 90
	iend
	istruc BasePoint
		at .vec, dd 11
		at .rad, db 166
	iend
SHIP_NUM_POINTS equ ($ - ship_base_points) / BasePoint_size


section .bss

ship                  resb Ship_size
ship_points           resb Point_size * SHIP_NUM_POINTS
ship_color            resb Pixel_size
ship_num_flashes_left resd    1
ship_flash_counter    resd    1

ship_teleport_shrink_vals_ind resd 1
ship_teleport_is_growing      resd 1


section .text

ship_respawn:
	mov [ship + Ship.x], SCREEN_WIDTH/2 << 16
	mov [ship + Ship.y], SCREEN_HEIGHT/2 << 16
	xor eax, eax
	mov [ship + Ship.rot], al
	mov [ship + Ship.velocity + Vector.x], eax
	mov [ship + Ship.velocity + Vector.y], eax
	mov dword [ship + Ship.respawn_counter], 0
	mov byte [ship + Ship.is_boosting], 0
	mov dword [ship_num_flashes_left], SHIP_NUM_FLASHES
	mov dword [ship_flash_counter], SHIP_FLASH_COUNTER_AMT
	mov dword [ship_teleport_shrink_vals_ind], 0
	mov dword [ship_teleport_is_growing], 0

	ret


; in:
	; rdi - pointer to Input struct
ship_update:
	cmp [ship + Ship.respawn_counter], 0
	je .normalUpdate
		dec [ship + Ship.respawn_counter]
		jne ._
		call ship_respawn
		lea r8, ship_base_points
		lea r9, ship_points
		call ship_setAllPoints
		._:
		ret
	.normalUpdate:
	bt [rdi + Input.buttons_down], Keys_Left
	jnc ._1
		sub [ship + Ship.rot], 3
		jmp .turnCheckEnd
	._1:
	bt [rdi + Input.buttons_down], Keys_Right
	jnc ._2
		add [ship + Ship.rot], 3
	._2:
	.turnCheckEnd:

	bt [rdi + Input.buttons_pressed], Keys_Fire
	jnc ._3
		mov r8d, [ship_points + Point.x]
		shl r8d, 16
		mov r9d, [ship_points + Point.y]
		shl r9d, 16
		mov r10b, [ship + Ship.rot]
		xor r11d, r11d ; not evil
		push rdi
		call bullet_create
		pop rdi

		; send event (for gamepad rumble)
		bts [event_bus], Event_Fire

		; kick
		xor rax, rax
		mov al, [ship + Ship.rot]
		add al, 128
		mov bl, al
		call sin
		cdqe
		imul rax, SHIP_VELOCITY_KICK
		sar rax, 31
		add [ship + Ship.velocity + Vector.x], eax
		xor rax, rax
		mov al, bl
		call cos
		cdqe
		imul rax, SHIP_VELOCITY_KICK
		sar rax, 31
		sub [ship + Ship.velocity + Vector.y], eax
	._3:

	; teleport animation
	mov eax, [ship_teleport_shrink_vals_ind]
	test eax, eax
	je .teleportAnimEnd
		cmp [ship_teleport_is_growing], 0
		je ._4
			dec [ship_teleport_shrink_vals_ind]
			setne byte [ship_teleport_is_growing]
			jmp .teleportAnimEnd
		._4:
			inc eax
			cmp eax, shrink_vals_len
			jl ._5
				inc [ship_teleport_is_growing]
				call ship_teleport
				jmp .teleportAnimEnd
			._5:
				mov [ship_teleport_shrink_vals_ind], eax
	.teleportAnimEnd:

	bt [rdi + Input.buttons_pressed], Keys_Teleport
	jnc ._6
	cmp [ship_teleport_shrink_vals_ind], 0
	jne ._6
		inc [ship_teleport_shrink_vals_ind]
	._6:

	; boost
	mov [ship + Ship.is_boosting], 0
	bt [rdi + Input.buttons_down], Keys_Boost
	jnc ._7
		inc [ship + Ship.is_boosting]
	
		xor rax, rax
		mov al, [ship + Ship.rot]
		call sin
		cdqe
		imul rax, SHIP_VELOCITY_ACCEL
		sar rax, 31
		add [ship + Ship.velocity + Vector.x], eax

		xor rax, rax
		mov al, [ship + Ship.rot]
		call cos
		cdqe
		imul rax, SHIP_VELOCITY_ACCEL
		sar rax, 31
		sub [ship + Ship.velocity + Vector.y], eax
	._7:

	; drag
	mov eax, [ship + Ship.velocity + Vector.x]
	test eax, eax
	je ._8
		cdqe
		imul rax, SHIP_VELOCITY_DRAG
		sar rax, 16
		mov [ship + Ship.velocity + Vector.x], eax
	._8:
	mov eax, [ship + Ship.velocity + Vector.y]
	test eax, eax
	je ._9
		cdqe
		imul rax, SHIP_VELOCITY_DRAG
		sar rax, 16
		mov [ship + Ship.velocity + Vector.y], eax
	._9:

	; velocity bounds check
	mov eax, [ship + Ship.velocity + Vector.x]
	cmp eax, SHIP_VELOCITY_MAX
	jg .xVelocitySetMax
	cmp eax, -SHIP_VELOCITY_MAX
	jg .yVeloCheck
	;xVelocitySetMin:
		mov [ship + Ship.velocity + Vector.x], -SHIP_VELOCITY_X
		jmp .yVeloCheck
	.xVelocitySetMax:
		mov [ship + Ship.velocity + Vector.x], SHIP_VELOCITY_MAX
	.yVeloCheck:

	mov eax, [ship + Ship.velocity + Vector.y]
	cmp eax, SHIP_VELOCITY_MAX
	jg .yVelocitySetMax
	cmp eax, -SHIP_VELOCITY_MAX
	jg .yVeloCheckEnd
	;yVelocitySetMin:
		mov [ship + Ship.velocity + Vector.y], -SHIP_VELOCITY_MAX
		jmp .yVeloCheckEnd
	.yVelocitySetMax:
		mov [ship + Ship.velocity + Vector.y], SHIP_VELOCITY_MAX
	.yVeloCheckEnd:

	; add velocity to position
	mov eax, [ship + Ship.velocity + Vector.x]
	add [ship + Ship.x], eax
	mov eax, [ship + Ship.velocity + Vector.y]
	add [ship + Ship.y], eax

	; wrap position
	lea rsi, ship
	call wrapPointAroundScreen

	lea r8, ship_base_points
	lea r9, ship_points
	call ship_setAllPoints

	; draw fire lines
	cmp [ship + Ship.is_boosting], 0
	je ._10
	mov rax, [frame_counter]
	and rax, 1b
	jne ._10
	mov rax, 0000ffff0000ffffh 
	mov r8, qword [ship_points + 3 * Point_size]
	and r8, rax
	shl r8, 16
	mov r10, qword [ship_points + 4 * Point_size]
	and r10, rax
	shl r10, 16
	xor ebx, ebx
	mov bl, [ship + Ship.rot]
	add bl, 128
	call fire_create
	._10:

	; flash (invincibility)
	cmp dword [ship_num_flashes_left], 0
	je .flashEnd
	dec dword [ship_flash_counter]
	jne .flashEnd
		mov dword [ship_flash_counter], SHIP_FLASH_COUNTER_AMT
		dec dword [ship_num_flashes_left]
		bt dword [ship_num_flashes_left], 0
		jc ._11
			mov eax, [fg_color]
			jmp .flashColStore
		._11:
			mov eax, [dim_color]
		.flashColStore:
		mov [ship_color], eax
	.flashEnd:

	call ship_checkBullets

	ret


; in:
	; r8 - pointer to first source BasePoint
	; r9 - pointer to first destination Point
	; TODO: I meant to make this method callable from game.s but I think I went back on that. can be refactored
ship_setAllPoints:
	push rbx
	push r10
	push r11
	push r12

	mov r11b, [ship + Ship.rot]
	lea r10, ship
	mov r12d, [ship_teleport_shrink_vals_ind]
	shl r12d, 2
	lea rax, shrink_vals
	mov r12d, [rax + r12]

	call applyBasePointToPoint

	%rep 4
	add r8, BasePoint_size
	add r9, Point_size
	call applyBasePointToPoint
	%endrep

	pop r12
	pop r11
	pop r10
	pop rbx
	ret


ship_destroy:
	push rbx
	push rcx
	push rdx
	push r8

	mov rbx, qword [ship]
	mov rcx, qword [ship + Ship.velocity]
	mov edx, 36
	mov r8b, [ship + Ship.rot]
	call shipShard_create

	mov rbx, qword [ship]
	mov rcx, qword [ship + Ship.velocity]
	mov edx, 16
	add r8b, 256/5
	call shipShard_create

	mov rbx, qword [ship]
	mov rcx, qword [ship + Ship.velocity]
	mov edx, 25
	add r8b, 256/5
	call shipShard_create

	mov rbx, qword [ship]
	mov rcx, qword [ship + Ship.velocity]
	mov edx, 12
	add r8b, 256/5
	call shipShard_create

	mov rbx, qword [ship]
	mov rcx, qword [ship + Ship.velocity]
	mov edx, 20
	add r8b, 256/5
	call shipShard_create

	bts [event_bus], Event_ShipDestroy ; for rumble

	dec dword [lives]
	cmp dword [lives], 0
	je .gameover
		mov [ship + Ship.respawn_counter], SHIP_RESPAWN_COUNTER
		jmp .end
	.gameover:
		mov eax, GAMEOVER_TIMER_AMT
		mov [gameover_timer], eax
		inc [is_in_gameover]
	.end:
	pop r8
	pop rdx
	pop rcx
	pop rbx
	ret


ship_checkBullets:
	push rbx
	push rcx
	push rsi
	push r8
	push r9

	cmp dword [ship_num_flashes_left], 0
	jne .noHit

	mov eax, [bullets_arr + Array.data.len]
	test eax, eax
	je .end
	xor ecx, ecx
	lea rsi, bullets
	.mainLoop:
		cmp [rsi + Bullet.is_evil], 0
		je .next

		; check if bullet is inside this ship's circular hitbox, dictacted by it's 'mass'
		; hit if (dx^2 + dy^2) <= r^2
		xor eax, eax ; clear upper bits
		mov ax, word [rsi + Bullet.pos.x + 2]
		sub ax, word [ship + Ship.x + 2]
		cwde
		imul eax, eax
		mov r8d, eax
		mov ax, word [rsi + Bullet.pos.y + 2]
		sub ax, word [ship + Ship.y + 2]
		cwde
		imul eax, eax
		mov r9d, eax

		add r8d, r9d
		cmp r8d, SHIP_R_SQ
		jg .next

		; hit!
		push rsi
		lea rsi, bullets_arr
		mov eax, ecx
		call array_removeAt
		pop rsi
		call ship_destroy
		mov eax, 1
		jmp .end

		.next:
		add rsi, Bullet_size
		inc ecx
		cmp ecx, [bullets_arr + Array.data.len]
		jb .mainLoop

	.noHit:
	xor eax, eax

	.end:
	pop r9
	pop r8
	pop rsi
	pop rcx
	pop rbx
	ret


SHIP_MAX_NUM_TELEPORT_TRIES equ 32
ship_teleport:
	push rbx
	push rcx
	push rsi
	push r8

	mov ecx, SHIP_MAX_NUM_TELEPORT_TRIES
	.checkLoop:
		call getRandomOnscreenFixedPointPos
		mov qword [ship], rax

		; check for asteroids
		mov ebx, 4 ; bigger asteroid radius for checking
		lea rsi, asteroids_arr
		lea r8, asteroid_checkShip
		call array_forEach
		; eax = 0 if free, -1 else
		test eax, eax
		loopne checkLoop

		; check for ufos
		lea rsi, ufos_arr
		lea r8, ufo_checkShip
		call array_forEach
		; eax = 0 if free, -1 else
		test eax, eax
		loopne checkLoop
	.checkLoopEnd:

	pop r8
	pop rsi
	pop rcx
	pop rbx
	ret



ship_draw:
	cmp [ship + Ship.respawn_counter], 0
	jne .end
	mov r8d, [ship_color]

	screen_mDrawLine ship_points + Point_size*0, ship_points + Point_size*1
	screen_mDrawLine ship_points + Point_size*0, ship_points + Point_size*2
	screen_mDrawLine ship_points + Point_size*3, ship_points + Point_size*4

	.end:
	ret



%endif
