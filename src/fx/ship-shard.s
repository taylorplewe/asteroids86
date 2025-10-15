ifndef shipShard_h
shipShard_h = 1

include <globaldefs.inc>

include <common.s>
include <array.s>


ShipShard struct
	pos          Point  <?> ; 16.16 fixed point
	velocity     Vector <?> ; 16.16 fixed point
	len          dd     ?
	rot          dw     ?   ; 8.8 fixed point
	rot_velocity dw     ?   ; 8.8 fixed point
	ticks_to_live dd ?
ShipShard ends

MAX_NUM_SHIP_SHARDS          = 8
SHIP_SHARD_MIN_TICKS_TO_LIVE = 120
SHIP_SHARD_VELOCITY_DIFF     = 24000h


.data

ship_shards     ShipShard MAX_NUM_SHIP_SHARDS dup (<>)
ship_shards_arr Array     { { ship_shards, 0 }, MAX_NUM_SHIP_SHARDS, sizeof ShipShard }


.code

; in:
	; rbx - pos
	; rcx - velocity
	; edx - len
	; r8b - rotation added to base velocity to fly in
shipShard_create proc
	lea rsi, ship_shards_arr
	call array_push
	test eax, eax
	je _end

	; brk
	mov rsi, rax
	mov qword ptr [rsi].ShipShard.pos, rbx
	mov qword ptr [rsi].ShipShard.velocity, rcx
	sar [rsi].ShipShard.velocity.x, 2
	sar [rsi].ShipShard.velocity.y, 2
	mov [rsi].ShipShard.len, edx

	; randomize values
	xor eax, eax
	rand eax
	mov [rsi].ShipShard.rot, ax
	sar eax, 16 + 5 ; upper word of eax, then "and" it with 00000111.11111111b (but signed)
	mov [rsi].ShipShard.rot_velocity, ax

	; ticks_to_live = also random
	rdrand eax
	and eax, 64 - 1 ; 0 - 64 (just over one second)
	add eax, SHIP_SHARD_MIN_TICKS_TO_LIVE
	mov [rsi].ShipShard.ticks_to_live, eax

	xor eax, eax
	mov al, r8b
	call sin
	cdqe
	imul rax, SHIP_SHARD_VELOCITY_DIFF
	sar rax, 32
	add [rsi].ShipShard.velocity.x, eax

	xor eax, eax
	mov al, r8b
	call cos
	cdqe
	imul rax, SHIP_SHARD_VELOCITY_DIFF
	sar rax, 32
	sub [rsi].ShipShard.velocity.y, eax
	
	_end:
	ret
shipShard_create endp

shipShard_updateAll proc
	lea rsi, ship_shards_arr
	lea r8, shipShard_update
	jmp array_forEach
shipShard_updateAll endp

; in:
	; rdi - pointer to ship shard
; out:
	; eax - 1 if ship shard is destroyed, 0 else
shipShard_update proc
	push rsi

	dec [rdi].ShipShard.ticks_to_live
	jne @f
		; destroy it
		lea rsi, ship_shards_arr
		call array_removeEl
		mov eax, 1
		jmp _end
	@@:

	; rotate shard
	xor eax, eax
	mov ax, [rdi].ShipShard.rot_velocity
	add [rdi].ShipShard.rot, ax

	; move shard
	; TODO: might be able to do this with 64-bit SIMD vectors?
	mov eax, [rdi].ShipShard.velocity.x
	add [rdi].ShipShard.pos.x, eax
	mov eax, [rdi].ShipShard.velocity.y
	add [rdi].ShipShard.pos.y, eax

	lea rsi, [rdi].ShipShard.pos
	call wrapPointAroundScreen

	normalExit:
	xor eax, eax
	_end:
	pop rsi
	ret
shipShard_update endp

shipShard_drawAll proc
	mov r14d, SCREEN_WIDTH
	mov r15d, SCREEN_HEIGHT

	lea rsi, ship_shards_arr
	lea r8, shipShard_draw
	jmp array_forEach
shipShard_drawAll endp

; in:
	; rdi - pointer to ship shard
; out:
	; eax - 0 (ship shard not destroyed)
shipShard_draw proc
	push rbx
	push rcx
	push rsi
	push rdi
	push r8

	; x
	; brk
	xor eax, eax
	mov al, byte ptr [rdi].ShipShard.rot + 1
	call sin
	cdqe
	mov ebx, [rdi].ShipShard.len
	imul rax, rbx
	sar rax, 32
	; p1
	xor ebx, ebx
	mov bx, word ptr [rdi].ShipShard.pos.x + 2
	add ebx, eax
	mov [screen_point1].x, ebx
	test ebx, ebx
	; p2
	xor ebx, ebx
	mov bx, word ptr [rdi].ShipShard.pos.x + 2
	sub ebx, eax
	mov [screen_point2].x, ebx
	test ebx, ebx
	; y
	xor eax, eax
	mov al, byte ptr [rdi].ShipShard.rot + 1
	call cos
	cdqe
	mov ebx, [rdi].ShipShard.len
	imul rax, rbx
	sar rax, 32
	; p1
	xor ebx, ebx
	mov bx, word ptr [rdi].ShipShard.pos.y + 2
	add ebx, eax
	mov [screen_point1].y, ebx
	; p2
	xor ebx, ebx
	mov bx, word ptr [rdi].ShipShard.pos.y + 2
	sub ebx, eax
	mov [screen_point2].y, ebx

	mov r8d, [fg_color]

	; fade out
	mov ebx, [rdi].ShipShard.ticks_to_live
	cmp ebx, 32
	jge @f
		shl ebx, 24 + 3
		and ebx, 0ff000000h
		and r8d, 00ffffffh
		or r8d, ebx
	@@:

	call screen_drawLine

	xor eax, eax
	pop r8
	pop rdi
	pop rsi
	pop rcx
	pop rbx
	ret
shipShard_draw endp


endif
