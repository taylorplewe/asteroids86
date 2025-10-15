ifndef shard_h
shard_h = 1

include <globaldefs.inc>

include <array.s>
include <screen.s>


Shard struct
	pos           Point  <?> ; 16.16 fixed point
	velocity      Vector <?> ; 16.16 fixed point
	mass          dd ?
	ticks_to_live dd ?
Shard ends

MAX_NUM_SHARDS      = 64
SHARD_VELOCITY_DIFF = 40000h ; 16.16 fixed point


.data

shards     Shard MAX_NUM_SHARDS dup (<>)
shards_arr Array { { shards, 0 }, MAX_NUM_SHARDS, sizeof Shard }


.code

; in:
	; rbx - pos
	; rcx - velocity
	; r8b - rotation added to base velocity to fly in
shard_create proc
	lea rsi, shards_arr
	call array_push
	test eax, eax
	je _end

	mov rsi, rax
	mov qword ptr [rsi].Shard.pos, rbx
	mov qword ptr [rsi].Shard.velocity, rcx

	; apply velocity rotation
	; x
	xor eax, eax
	mov al, r8b
	call sin
	cdqe
	imul rax, SHARD_VELOCITY_DIFF
	sar rax, 32
	add [rsi].Shard.velocity.x, eax
	; y
	xor eax, eax
	mov al, r8b
	call cos
	cdqe
	imul rax, SHARD_VELOCITY_DIFF
	sar rax, 32
	sub [rsi].Shard.velocity.y, eax

	_end:
	ret
shard_create endp

shard_updateAll proc
	lea rsi, shards_arr
	lea r8, shard_update
	jmp array_forEach
shard_updateAll endp

; in:
	; rdi - pointer to shard
; out:
	; eax - 1 if shard was destroyed, 0 else
shard_update proc
	push rsi

	dec [rdi].Shard.ticks_to_live
	jne @f
		; destroy it
		lea rsi, shards_arr
		call array_removeEl
		mov eax, 1
		jmp _end
	@@:

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
shard_update endp

shard_drawAll proc
	lea rsi, shards_arr
	lea r8, shard_draw
	jmp array_forEach
shard_drawAll endp

; in:
	; rdi - pointer to shard
; out:
	; eax - 0 (shard was not destroyed)
shard_draw proc
	xor eax, eax
	ret
shard_draw endp


endif
