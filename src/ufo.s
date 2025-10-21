ifndef ufo_h
ufo_h = 1

include <globaldefs.inc>
include <windows.inc>

include <common.s>
include <array.s>
include <screen.s>
include <bullet.s>
include <ship.s>


Ufo struct
	pos         Point  <?>
	velocity    Vector <?>
	targ_pos    Point  <?>
	shoot_timer dd     ?
	frame_ind   dd     ?
	frame_ctr   dd     ?
	turn_timer  dd     ?
	rot         db     ?
Ufo ends

MAX_NUM_UFOS           = 4
UFO_NUM_FRAMES         = 4
UFO_FRAME_CTR_AMT      = 6
UFO_BBOX_WIDTH         = 84
UFO_BBOX_HEIGHT        = 124
UFO_SHOOT_TIMER_AMT    = 64
UFO_TURN_TIMER_MIN_AMT = 60 * 1
UFO_TURN_TIMER_MAX_AMT = 60 * 6
UFO_TURN_ROT           = 32
UFO_SPEED              = 2


.data

ufos_arr                Array { { ufos, 0 }, MAX_NUM_UFOS, sizeof Ufo }
ufo_spr_resource_name_0 byte  "UFOBIN0", 0
ufo_spr_resource_name_1 byte  "UFOBIN1", 0
ufo_spr_resource_name_2 byte  "UFOBIN2", 0
ufo_spr_resource_name_3 byte  "UFOBIN3", 0
ufo_resource_type       byte  "BIN", 0


.data?

ufos         Ufo MAX_NUM_UFOS dup (<>)
ufo_spr_data dq  ?
             dq  ?
             dq  ?
             dq  ?


.code

ufo_init proc
	push rbp
	mov rbp, rsp
	sub rsp, 200h

	xor rcx, rcx
	lea rdx, ufo_spr_resource_name_0
	lea r8, ufo_resource_type
	call FindResourceA
	xor rcx, rcx
	mov rdx, rax
	call LoadResource
	mov rcx, rax
	call LockResource
	mov [ufo_spr_data], rax
 
	xor rcx, rcx
	lea rdx, ufo_spr_resource_name_1
	lea r8, ufo_resource_type
	call FindResourceA
	xor rcx, rcx
	mov rdx, rax
	call LoadResource
	mov rcx, rax
	call LockResource
	mov [ufo_spr_data + 8], rax
 
	xor rcx, rcx
	lea rdx, ufo_spr_resource_name_2
	lea r8, ufo_resource_type
	call FindResourceA
	xor rcx, rcx
	mov rdx, rax
	call LoadResource
	mov rcx, rax
	call LockResource
	mov [ufo_spr_data + 16], rax
 
	xor rcx, rcx
	lea rdx, ufo_spr_resource_name_3
	lea r8, ufo_resource_type
	call FindResourceA
	xor rcx, rcx
	mov rdx, rax
	call LoadResource
	mov rcx, rax
	call LockResource
	mov [ufo_spr_data + 24], rax
 
	mov rsp, rbp
	pop rbp
	ret
ufo_init endp

; in:
	; rbx - pos
ufo_create proc
	lea rsi, ufos_arr
	call array_push
	test eax, eax
	je _end

	mov rsi, rax
	mov qword ptr [rsi].Ufo.pos, rbx
	mov [rsi].Ufo.frame_ind, 0
	mov [rsi].Ufo.frame_ctr, UFO_FRAME_CTR_AMT
	mov [rsi].Ufo.velocity.x, 10000h
	mov [rsi].Ufo.velocity.y, 0
	mov [rsi].Ufo.shoot_timer, UFO_SHOOT_TIMER_AMT
	mov [rsi].Ufo.turn_timer, UFO_TURN_TIMER_MIN_AMT

	mov [rsi].Ufo.rot, 64
	xor r10, r10
	mov r10b, [rsi].Ufo.rot
	mov ecx, UFO_SPEED
	call getVelocityFromRotAndSpeed
	mov qword ptr [rsi].Ufo.velocity, rax
	
	_end:
	ret
ufo_create endp

ufo_updateAll proc
	lea rsi, ufos_arr
	lea r8, ufo_update
	jmp array_forEach
ufo_updateAll endp

; in:
	; rdi - pointer to UFO
; out:
	; eax - 1 if UFO was destroyed, 0 else
ufo_update proc
	push rbx
	push rcx
	push r8
	push r9
	push r10

	; advance frame
	dec [rdi].Ufo.frame_ctr
	jne frameCtrIncEnd
		mov [rdi].Ufo.frame_ctr, UFO_FRAME_CTR_AMT
		inc [rdi].Ufo.frame_ind
		and [rdi].Ufo.frame_ind, 11b
	frameCtrIncEnd:

	; turn
	xor r10, r10
	dec [rdi].Ufo.turn_timer
	jne turnEnd
		mov [rdi].Ufo.turn_timer, UFO_TURN_TIMER_MIN_AMT
		cmp [rdi].Ufo.velocity.y, 0
		jne turnStraight
			mov r10b, [rdi].Ufo.rot
			rand eax
			and eax, 1
			dec eax
			or eax, 1 ; eax = -1 or 1
			imul eax, UFO_TURN_ROT
			add r10b, al
			jmp doTurn
		turnStraight:
		cmp [rdi].Ufo.velocity.x, 0
		jge turnRight
		; turnLeft:
			mov r10b, 196
			jmp doTurn
		turnRight:
			mov r10b, 64
		doTurn:
		mov [rdi].Ufo.rot, r10b
		mov ecx, UFO_SPEED
		call getVelocityFromRotAndSpeed
		mov qword ptr [rdi].Ufo.velocity, rax
	turnEnd:

	; move
	movd xmm0, [rdi].Ufo.pos
	movd xmm1, [rdi].Ufo.velocity
	paddd xmm0, xmm1
	movd [rdi].Ufo.pos, xmm0

	; wrap around screen
	push rsi
	lea rsi, [rdi].Ufo.pos
	call wrapPointAroundScreen
	pop rsi

	; shoot
	cmp [ship].ticks_to_respawn, 0
	jne shootEnd
	dec [rdi].Ufo.shoot_timer
	jne shootEnd
		; r8d - X 16.16 fixed point
		; r9d - Y 16.16 fixed point
		; r10b - rotation in 256-based radians

		mov ebx, [ship].y
		sub ebx, [rdi].Ufo.pos.y
		sar ebx, 16
		mov ecx, [ship].x
		sub ecx, [rdi].Ufo.pos.x
		sar ecx, 16
		; brk
		call atan2
		xor r10, r10
		mov r10b, al
		
		mov r8d, [rdi].Ufo.pos.x
		mov r9d, [rdi].Ufo.pos.y
		mov r11d, 1

		call bullet_create

		mov [rdi].Ufo.shoot_timer, UFO_SHOOT_TIMER_AMT
	shootEnd:

	; check for bullets
	call ufo_checkBullets ; returns 1 if hit, 0 else
	test eax, eax
	jne _end
	call ufo_checkShip ; returns 1 if hit, 0 else

	_end:
	pop r10
	pop r9
	pop r8
	pop rcx
	pop rbx
	ret
ufo_update endp

; in:
	; rdi - pointer to UFO
ufo_checkBullets proc
	push rcx
	push rsi

	mov eax, [bullets_arr].Array.data.len
	test eax, eax
	je noHit
	xor ecx, ecx
	lea rsi, bullets
	mainLoop:
		; must not be evil to hit
		cmp [rsi].Bullet.is_evil, 0
		jne next
	
		; check if bullet is inside UFO's rectangular hitbox
		; < x
		xor eax, eax
		mov ax, word ptr [rdi].Ufo.pos.x + 2
		sub eax, UFO_BBOX_WIDTH / 2
		cmp ax, word ptr [rsi].Bullet.pos.x + 2
		jg next
		; > x
		add eax, UFO_BBOX_WIDTH
		cmp ax, word ptr [rsi].Bullet.pos.x + 2
		jl next
		; < y
		xor eax, eax
		mov ax, word ptr [rdi].Ufo.pos.y + 2
		sub eax, UFO_BBOX_HEIGHT / 2
		cmp ax, word ptr [rsi].Bullet.pos.y + 2
		jg next
		; > y
		add eax, UFO_BBOX_HEIGHT
		cmp ax, word ptr [rsi].Bullet.pos.y + 2
		jl next

		; hit!
		push rsi
		lea rsi, bullets_arr
		mov eax, ecx
		call array_removeAt
		pop rsi
		call ufo_destroy
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
	pop rsi
	pop rcx
	ret
ufo_checkBullets endp

ufo_checkShip proc
	; check if bullet is inside UFO's rectangular hitbox
	; < x
	xor eax, eax
	mov ax, word ptr [rdi].Ufo.pos.x + 2
	sub eax, UFO_BBOX_WIDTH / 2
	cmp ax, word ptr [ship].x + 2
	jg noHit
	; > x
	add eax, UFO_BBOX_WIDTH
	cmp ax, word ptr [ship].x + 2
	jl noHit
	; < y
	xor eax, eax
	mov ax, word ptr [rdi].Ufo.pos.y + 2
	sub eax, UFO_BBOX_HEIGHT / 2
	cmp ax, word ptr [ship].y + 2
	jg noHit
	; > y
	add eax, UFO_BBOX_HEIGHT
	cmp ax, word ptr [ship].y + 2
	jl noHit

	call ship_destroy
	call ufo_destroy
	mov eax, 1
	ret

	noHit:
	xor eax, eax
	ret
ufo_checkShip endp

; in:
	; rdi - pointer to ufo
ufo_destroy proc
	push rbx
	push rcx
	push rdx
	push r8

	UFO_DESTROY_Y_DIFF = UFO_BBOX_HEIGHT / 9
	UFO_DESTROY_X_DIFF = UFO_BBOX_WIDTH / 6
	UFO_DESTROY_ROT    = 30

	mov r8b, -UFO_DESTROY_ROT
	mov rcx, ((UFO_DESTROY_Y_DIFF) shl 48) or ((UFO_DESTROY_X_DIFF) shl 16)
	mov rbx, qword ptr [rdi].Ufo.pos
	sub rbx, rcx
	mov rcx, qword ptr [rdi].Ufo.velocity
	mov edx, 20
	call shipShard_create

	add r8b, UFO_DESTROY_ROT
	mov rcx, (UFO_DESTROY_Y_DIFF) shl 48
	sub rbx, rcx
	mov rcx, (UFO_DESTROY_X_DIFF) shl 16
	add rbx, rcx
	mov rcx, qword ptr [rdi].Ufo.velocity
	mov edx, 20
	call shipShard_create

	add r8b, UFO_DESTROY_ROT
	mov rcx, ((UFO_DESTROY_Y_DIFF) shl 48) or ((UFO_DESTROY_X_DIFF) shl 16)
	add rbx, rcx
	mov rcx, qword ptr [rdi].Ufo.velocity
	mov edx, 20
	call shipShard_create

	mov r8b, 128 - UFO_DESTROY_ROT
	mov rcx, (UFO_DESTROY_Y_DIFF * 2) shl 48
	add rbx, rcx
	mov rcx, qword ptr [rdi].Ufo.velocity
	mov edx, 20
	call shipShard_create

	add r8b, UFO_DESTROY_ROT
	mov rcx, (UFO_DESTROY_Y_DIFF) shl 48
	add rbx, rcx
	mov rcx, (UFO_DESTROY_X_DIFF) shl 16
	sub rbx, rcx
	mov rcx, qword ptr [rdi].Ufo.velocity
	mov edx, 20
	call shipShard_create

	add r8b, UFO_DESTROY_ROT
	mov rcx, ((UFO_DESTROY_Y_DIFF) shl 48) or ((UFO_DESTROY_X_DIFF) shl 16)
	sub rbx, rcx
	mov rcx, qword ptr [rdi].Ufo.velocity
	mov edx, 20
	call shipShard_create

	mov rbx, qword ptr [rdi].Ufo.pos
	mov rcx, qword ptr [rdi].Ufo.velocity
	call shard_createBurst

	lea rsi, ufos_arr
	call array_removeEl

	pop r8
	pop rdx
	pop rcx
	pop rbx
	ret
ufo_destroy endp

ufo_drawAll proc
	lea rsi, ufos_arr
	lea r8, ufo_draw
	jmp array_forEach
ufo_drawAll endp

; in:
	; rdi - pointer to UFO
; out:
	; eax - 0 (UFO was not destroyed)
ufo_draw proc
	; rdx - pointer to Pos
	; rsi - pointer to sprite data
	; r9  - pointer to sprite Dim
	; r8d - color
	push rdx
	push rsi
	push r8
	push r9

	lea rdx, [rdi].Ufo.pos
	mov eax, [rdi].Ufo.frame_ind
	shl eax, 3 ; x8
	lea rsi, ufo_spr_data
	add rsi, rax
	mov rsi, [rsi]
	mov r8d, [fg_color]
	call screen_draw1bppSprite

	xor eax, eax
	pop r9
	pop r8
	pop rsi
	pop rdx
	ret
ufo_draw endp



endif
