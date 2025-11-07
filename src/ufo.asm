%ifndef ufo_h
%define ufo_h

%include "src/globaldefs.inc"

%include "src/global.asm"
%include "src/common.asm"
%include "src/array.asm"
%include "src/screen.asm"
%include "src/bullet.asm"
%include "src/ship.asm"


struc Ufo
	.pos:         resb Point_size
	.velocity:    resb Vector_size
	.targ_pos:    resb Point_size
	.shoot_timer: resd     1
	.frame_ind:   resd     1
	.frame_ctr:   resd     1
	.turn_timer:  resd     1
	.rot:         resb     1
endstruc

MAX_NUM_UFOS           equ 4
UFO_NUM_FRAMES         equ 4
UFO_FRAME_CTR_AMT      equ 6
UFO_SPR_WIDTH          equ 80
UFO_SPR_HEIGHT         equ 112
UFO_BBOX_WIDTH         equ 84
UFO_BBOX_HEIGHT        equ 124
UFO_SHOOT_TIMER_AMT    equ 64
UFO_TURN_TIMER_MIN_AMT equ 60 * 1
UFO_TURN_TIMER_MAX_AMT equ 60 * 6
UFO_TURN_ROT           equ 32
UFO_SPEED              equ 2
UFO_SCORE_ADD          equ 200


section .data

ufos_arr:
	istruc Array
		istruc FatPtr
			at .pntr, dq ufos
			at .len, dd 0
		iend
		at .cap, dd MAX_NUM_UFOS
		at .el_size, dd Ufo_size
	iend
ufo_spr_resource_name: db  "UFOBIN", 0
ufo_rect:
	istruc Rect
		istruc Point
			at .x, dd 0
			at .y, dd 0
		iend
		istruc Dim
			at .w, dd 0
			at .h, dd 0
		iend
	iend


section .bss

ufos         resb Ufo_size * MAX_NUM_UFOS
ufo_spr_data resq  1


section .text

ufo_initSprData:
	push rbp
	mov rbp, rsp
	sub rsp, 200h

	xor rcx, rcx
	lea rdx, ufo_spr_resource_name
	lea r8, bin_resource_type
	call FindResourceA
	xor rcx, rcx
	mov rdx, rax
	call LoadResource
	mov rcx, rax
	call LockResource
	mov [ufo_spr_data], rax

 	mov rsp, rbp
	pop rbp
	ret


; in:
	; rbx - pos
ufo_create:
	lea rsi, ufos_arr
	call array_push
	test eax, eax
	je .end

	mov rsi, rax
	mov qword [rsi + Ufo.pos], rbx
	mov [rsi + Ufo.frame_ind], 0
	mov [rsi + Ufo.frame_ctr], UFO_FRAME_CTR_AMT
	mov [rsi + Ufo.shoot_timer], UFO_SHOOT_TIMER_AMT
	mov [rsi + Ufo.turn_timer], UFO_TURN_TIMER_MIN_AMT

	; determine which way to fly based on which side of the screen we're on
	cmp [rsi + Ufo.pos.x], 0
	jg ._
		mov al, 64
		jmp .rotSet
	._:
		mov al, 192
	.rotSet:

	mov [rsi + Ufo.rot], al
	xor r10, r10
	mov r10b, [rsi + Ufo.rot]
	mov ecx, UFO_SPEED
	call getVelocityFromRotAndSpeed
	mov qword [rsi + Ufo.velocity], rax
	
	.end:
	ret


ufo_updateAll:
	lea rsi, ufos_arr
	lea r8, ufo_update
	jmp array_forEach


; in:
	; rdi - pointer to UFO
; out:
	; eax - 1 if UFO was destroyed, 0 else
ufo_update:
	push rbx
	push rcx
	push r8
	push r9
	push r10

	; advance frame
	dec [rdi + Ufo.frame_ctr]
	jne .frameCtrIncEnd
		mov [rdi + Ufo.frame_ctr], UFO_FRAME_CTR_AMT
		inc [rdi + Ufo.frame_ind]
		and [rdi + Ufo.frame_ind], 11b
	.frameCtrIncEnd:

	; turn
	xor r10, r10
	dec [rdi + Ufo.turn_timer]
	jne .turnEnd
		mov [rdi + Ufo.turn_timer], UFO_TURN_TIMER_MIN_AMT
		cmp [rdi + Ufo.velocity.y], 0
		jne .turnStraight
			mov r10b, [rdi + Ufo.rot]
			rand eax
			and eax, 1
			dec eax
			or eax, 1 ; eax = -1 or 1
			imul eax, UFO_TURN_ROT
			add r10b, al
			jmp .doTurn
		.turnStraight:
		cmp [rdi + Ufo.velocity.x], 0
		jge .turnRight
		; turnLeft:
			mov r10b, 192
			jmp .doTurn
		.turnRight:
			mov r10b, 64
		.doTurn:
		mov [rdi + Ufo.rot], r10b
		mov ecx, UFO_SPEED
		call getVelocityFromRotAndSpeed
		mov qword [rdi + Ufo.velocity], rax
	.turnEnd:

	; move
	movd xmm0, [rdi + Ufo.pos]
	movd xmm1, [rdi + Ufo.velocity]
	paddd xmm0, xmm1
	movd [rdi + Ufo.pos], xmm0

	; out of bounds?
	xor eax, eax
	mov ax, word [rdi + Ufo.pos.x + 2]
	cwde
	cmp eax, SCREEN_WIDTH + UFO_BBOX_WIDTH / 2
	jge .deleteUfo
	cmp eax, -UFO_BBOX_WIDTH / 2
	jl .deleteUfo
	mov ax, word [rdi + Ufo.pos.y + 2]
	cwde
	cmp eax, SCREEN_HEIGHT + UFO_BBOX_HEIGHT / 2
	jge .deleteUfo
	cmp eax, -UFO_BBOX_HEIGHT / 2
	jge .boundsCheckEnd
	.deleteUfo:
	lea rsi, ufos_arr
	call array_removeEl
	.boundsCheckEnd:

	; shoot
	cmp [ship + Ship.respawn_counter], 0
	jne .shootEnd
	cmp [is_in_gameover], 0
	jne .shootEnd
	dec [rdi + Ufo.shoot_timer]
	jne .shootEnd
		; r8d - X 16.16 fixed point
		; r9d - Y 16.16 fixed point
		; r10b - rotation in 256-based radians

		mov ebx, [ship + Ship.y]
		sub ebx, [rdi + Ufo.pos.y]
		sar ebx, 16
		mov ecx, [ship + Ship.x]
		sub ecx, [rdi + Ufo.pos.x]
		sar ecx, 16
		call atan2
		xor r10, r10
		mov r10b, al
		
		mov r8d, [rdi + Ufo.pos.x]
		mov r9d, [rdi + Ufo.pos.y]
		mov r11d, 1

		call bullet_create

		mov [rdi + Ufo.shoot_timer], UFO_SHOOT_TIMER_AMT
	.shootEnd:

	; check for bullets
	call ufo_checkBullets ; returns 1 if hit, 0 else
	test eax, eax
	jne .end
	call ufo_checkAndDestroyShip ; returns 1 if hit, 0 else

	.end:
	pop r10
	pop r9
	pop r8
	pop rcx
	pop rbx
	ret


; in:
	; rdi - pointer to UFO
ufo_checkBullets:
	push rcx
	push rsi

	mov eax, [bullets_arr + Array.data.len]
	test eax, eax
	je .noHit
	xor ecx, ecx
	lea rsi, bullets
	.mainLoop:
		; must not be evil to hit
		cmp [rsi + Bullet.is_evil], 0
		jne .next
	
		; check if bullet is inside UFO's rectangular hitbox
		; < x
		xor eax, eax
		mov ax, word [rdi + Ufo.pos.x + 2]
		sub eax, UFO_BBOX_WIDTH / 2
		cmp ax, word [rsi + Bullet.pos.x + 2]
		jg .next
		; > x
		add eax, UFO_BBOX_WIDTH
		cmp ax, word [rsi + Bullet.pos.x + 2]
		jl .next
		; < y
		xor eax, eax
		mov ax, word [rdi + Ufo.pos.y + 2]
		sub eax, UFO_BBOX_HEIGHT / 2
		cmp ax, word [rsi + Bullet.pos.y + 2]
		jg .next
		; > y
		add eax, UFO_BBOX_HEIGHT
		cmp ax, word [rsi + Bullet.pos.y + 2]
		jl .next

		; hit!
		mov eax, UFO_SCORE_ADD
		add [score], eax

		push rsi
		lea rsi, bullets_arr
		mov eax, ecx
		call array_removeAt
		pop rsi
		call ufo_destroy
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
	pop rsi
	pop rcx
	ret


; in:
	; rdi - pointer to ufo
; out:
	; eax - 0 if free, -1 else
ufo_checkShip:
	; check if bullet is inside UFO's rectangular hitbox
	; < x
	xor eax, eax
	mov ax, word [rdi + Ufo.pos.x + 2]
	sub eax, UFO_BBOX_WIDTH / 2
	cmp ax, word [ship + Ship.x + 2]
	jg .noHit
	; > x
	add eax, UFO_BBOX_WIDTH
	cmp ax, word [ship + Ship.x + 2]
	jl .noHit
	; < y
	xor eax, eax
	mov ax, word [rdi + Ufo.pos.y + 2]
	sub eax, UFO_BBOX_HEIGHT / 2
	cmp ax, word [ship + Ship.y + 2]
	jg .noHit
	; > y
	add eax, UFO_BBOX_HEIGHT
	cmp ax, word [ship + Ship.y + 2]
	jl .noHit

	; hit!
	mov eax, -1
	ret

	.noHit:
	xor eax, eax
	ret


ufo_checkAndDestroyShip:
	cmp [ship_num_flashes_left], 0
	jne .noHit
	cmp [is_in_gameover], 0
	jne .noHit
	cmp [ship + Ship.respawn_counter], 0
	jne .noHit

	call ufo_checkShip
	test eax, eax
	je .noHit

	call ship_destroy
	call ufo_destroy
	mov eax, 1
	ret

	.noHit:
	xor eax, eax
	ret


; in:
	; rdi - pointer to ufo
ufo_destroy:
	push rbx
	push rcx
	push rdx
	push r8

	UFO_DESTROY_Y_DIFF equ UFO_BBOX_HEIGHT / 9
	UFO_DESTROY_X_DIFF equ UFO_BBOX_WIDTH / 6
	UFO_DESTROY_ROT    equ 30

	mov r8b, -UFO_DESTROY_ROT
	mov rcx, ((UFO_DESTROY_Y_DIFF) << 48) | ((UFO_DESTROY_X_DIFF) << 16)
	mov rbx, qword [rdi + Ufo.pos]
	sub rbx, rcx
	mov rcx, qword [rdi + Ufo.velocity]
	mov edx, 20
	call shipShard_create

	add r8b, UFO_DESTROY_ROT
	mov rcx, (UFO_DESTROY_Y_DIFF) << 48
	sub rbx, rcx
	mov rcx, (UFO_DESTROY_X_DIFF) << 16
	add rbx, rcx
	mov rcx, qword [rdi + Ufo.velocity]
	mov edx, 20
	call shipShard_create

	add r8b, UFO_DESTROY_ROT
	mov rcx, ((UFO_DESTROY_Y_DIFF) << 48) | ((UFO_DESTROY_X_DIFF) << 16)
	add rbx, rcx
	mov rcx, qword [rdi + Ufo.velocity]
	mov edx, 20
	call shipShard_create

	mov r8b, 128 - UFO_DESTROY_ROT
	mov rcx, (UFO_DESTROY_Y_DIFF * 2) << 48
	add rbx, rcx
	mov rcx, qword [rdi + Ufo.velocity]
	mov edx, 20
	call shipShard_create

	add r8b, UFO_DESTROY_ROT
	mov rcx, (UFO_DESTROY_Y_DIFF) << 48
	add rbx, rcx
	mov rcx, (UFO_DESTROY_X_DIFF) << 16
	sub rbx, rcx
	mov rcx, qword [rdi + Ufo.velocity]
	mov edx, 20
	call shipShard_create

	add r8b, UFO_DESTROY_ROT
	mov rcx, ((UFO_DESTROY_Y_DIFF) << 48) | ((UFO_DESTROY_X_DIFF) << 16)
	sub rbx, rcx
	mov rcx, qword [rdi + Ufo.velocity]
	mov edx, 20
	call shipShard_create

	mov rbx, qword [rdi + Ufo.pos]
	mov rcx, qword [rdi + Ufo.velocity]
	call shard_createBurst

	lea rsi, ufos_arr
	call array_removeEl

	pop r8
	pop rdx
	pop rcx
	pop rbx
	ret


ufo_drawAll:
	lea rsi, ufos_arr
	lea r8, ufo_draw
	jmp array_forEach


; in:
	; rdi - pointer to UFO
; out:
	; eax - 0 (UFO was not destroyed)
ufo_draw:
	push rdx
	push rsi
	push r8
	push r9

	lea rdx, [rdi + Ufo.pos]
	mov rsi, [ufo_spr_data]
	mov r8d, [fg_color]
	lea r9, ufo_rect
	lea r14, screen_setPixelClipped

	; set (U, V) (V is always zero)
	mov eax, [rdi + Ufo.frame_ind]
	imul eax, [ufo_rect + Rect.dim.w]
	mov [ufo_rect + Rect.pos.x], eax

	call screen_draw1bppSprite

	xor eax, eax
	pop r9
	pop r8
	pop rsi
	pop rdx
	ret




%endif
