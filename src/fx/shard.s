%ifndef shard_h
%define shard_h

%include "globaldefs.inc"

%include "array.s"
%include "screen.s"


struc Shard
	pos           Point  <?> ; 16.16 fixed point
	velocity      Vector <?> ; 16.16 fixed point
	radius        dd ?
	ticks_to_live dd ?
endstruc

MAX_NUM_SHARDS          = 128
SHARD_VELOCITY_DIFF     = 20000h ; 16.16 fixed point
SHARD_MIN_TICKS_TO_LIVE = 90


.data

shards     Shard MAX_NUM_SHARDS dup (<>)
shards_arr Array { { shards, 0 }, MAX_NUM_SHARDS, sizeof Shard }


.code

; in:
	; rbx - pos
	; rcx - velocity
shard_createBurst proc
	push r8

	movd xmm0, rcx
	psrad xmm0, 2
	movd rcx, xmm0

	SHARD_CREATE_BURST_REPS = 14
	LoopInd = SHARD_CREATE_BURST_REPS

	xor r8, r8
	while LoopInd gt 0
		call shard_create
		add r8d, 256/SHARD_CREATE_BURST_REPS
		LoopInd = LoopInd - 1
	endm

	pop r8
	ret
shard_createBurst endp

; in:
	; rbx - pos
	; rcx - velocity
	; r8b - rotation added to base velocity to fly in
shard_create proc
	push rbx

	lea rsi, shards_arr
	call array_push
	test eax, eax
	je _end

	mov rsi, rax
	mov qword ptr [rsi].Shard.pos, rbx
	mov qword ptr [rsi].Shard.velocity, rcx

	xor eax, eax
	rand ax ; random number from 0 - 0xffff (practicaly 1.0 in 16.16 fixed point)
	imul rax, SHARD_VELOCITY_DIFF
	shr rax, 16
	mov ebx, eax

	; apply velocity rotation
	; x
	xor eax, eax
	mov al, r8b
	call sin
	cdqe
	imul rax, rbx
	sar rax, 32
	add [rsi].Shard.velocity.x, eax
	; y
	xor eax, eax
	mov al, r8b
	call cos
	cdqe
	imul rax, rbx
	sar rax, 32
	sub [rsi].Shard.velocity.y, eax

	rand eax
	and eax, 11b
	add eax, 2
	mov [rsi].Shard.radius, eax

	; ticks_to_live = also random
	rand eax
	and eax, 64 - 1 ; 0 - 64 (just over one second)
	add eax, SHARD_MIN_TICKS_TO_LIVE
	mov [rsi].Shard.ticks_to_live, eax

	_end:
	pop rbx
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
	mov r14d, SCREEN_WIDTH
	mov r15d, SCREEN_HEIGHT

	lea rsi, shards_arr
	lea r8, shard_draw
	jmp array_forEach
shard_drawAll endp

; in:
	; rdi - pointer to shard
; out:
	; eax - 0 (shard was not destroyed)
shard_draw proc
	push rbx
	push rcx
	push r8

	mov r8d, [fg_color]
	; fade out
	mov ebx, [rdi].Shard.ticks_to_live
	cmp ebx, 64
	jge @f
		shl ebx, 24 + 2
		and ebx, 0ff000000h
		and r8d, 00ffffffh
		or r8d, ebx
	@@:

	xor ebx, ebx
	xor ecx, ecx
	mov bx, word ptr [rdi].Shard.pos.x + 2
	mov cx, word ptr [rdi].Shard.pos.y + 2

	mov edx, [rdi].Shard.radius ; circle radius

	call screen_drawCircle

	xor eax, eax
	pop r8
	pop rcx
	pop rbx
	ret
shard_draw endp


%endif
