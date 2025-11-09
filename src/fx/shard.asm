%ifndef shard_h
%define shard_h

%include "src/globaldefs.inc"

%include "src/array.asm"
%include "src/screen.asm"


struc Shard
	.pos:           resb Point_size ; 16.16 fixed point
	.velocity:      resb Vector_size ; 16.16 fixed point
	.radius:        resd 1
	.ticks_to_live: resd 1
endstruc

MAX_NUM_SHARDS          equ 128
SHARD_VELOCITY_DIFF     equ 20000h ; 16.16 fixed point
SHARD_MIN_TICKS_TO_LIVE equ 90


section .data

; shards_arr Array { { shards, 0 }, MAX_NUM_SHARDS, Shard_size }
shards_arr:
	istruc Array
		istruc FatPtr
			at .pntr, dq shards
			at .len, dd 0
		iend
		at .cap, dd MAX_NUM_SHARDS
		at .el_size, dd Shard_size
	iend


section .bss

shards: resb Shard_size * MAX_NUM_SHARDS


section .text

; in:
	; rbx - pos
	; rcx - velocity
shard_createBurst:
	push r8

	movd xmm0, ecx
	psrad xmm0, 2
	movd ecx, xmm0

	SHARD_CREATE_BURST_REPS equ 14

	xor r8, r8
	%rep SHARD_CREATE_BURST_REPS
		call shard_create
		add r8d, 256 / SHARD_CREATE_BURST_REPS
	%endrep

	pop r8
	ret


; in:
	; rbx - pos
	; rcx - velocity
	; r8b - rotation added to base velocity to fly in
shard_create:
	push rbx

	lea rsi, shards_arr
	call array_push
	test eax, eax
	je .end

	mov rsi, rax
	mov qword [rsi + Shard.pos], rbx
	mov qword [rsi + Shard.velocity], rcx

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
	add [rsi + Shard.velocity + Point.x], eax
	; y
	xor eax, eax
	mov al, r8b
	call cos
	cdqe
	imul rax, rbx
	sar rax, 32
	sub [rsi + Shard.velocity + Point.y], eax

	rand eax
	and eax, 11b
	add eax, 2
	mov [rsi + Shard.radius], eax

	; ticks_to_live = also random
	rand eax
	and eax, 64 - 1 ; 0 - 64 (just over one second)
	add eax, SHARD_MIN_TICKS_TO_LIVE
	mov [rsi + Shard.ticks_to_live], eax

	.end:
	pop rbx
	ret


shard_updateAll:
	lea rsi, shards_arr
	lea r8, shard_update
	jmp array_forEach


; in:
	; rdi - pointer to shard
; out:
	; eax - 1 if shard was destroyed, 0 else
shard_update:
	push rsi

	dec [rdi + Shard.ticks_to_live]
	jne ._
		; destroy it
		lea rsi, shards_arr
		call array_removeEl
		mov eax, 1
		jmp .end
	._:

	; move shard
	; TODO: might be able to do this with 64-bit SIMD vectors?
	mov eax, [rdi + ShipShard.velocity + Point.x]
	add [rdi + ShipShard.pos + Point.x], eax
	mov eax, [rdi + ShipShard.velocity + Point.y]
	add [rdi + ShipShard.pos + Point.y], eax

	lea rsi, [rdi + ShipShard.pos]
	call wrapPointAroundScreen

	.normalExit:
	xor eax, eax
	.end:
	pop rsi
	ret


shard_drawAll:
	mov r14d, SCREEN_WIDTH
	mov r15d, SCREEN_HEIGHT

	lea rsi, shards_arr
	lea r8, shard_draw
	jmp array_forEach


; in:
	; rdi - pointer to shard
; out:
	; eax - 0 (shard was not destroyed)
shard_draw:
	push rbx
	push rcx
	push r8

	mov r8d, [fg_color]
	; fade out
	mov ebx, [rdi + Shard.ticks_to_live]
	cmp ebx, 64
	jge ._
		shl ebx, 24 + 2
		and ebx, 0ff000000h
		and r8d, 00ffffffh
		or r8d, ebx
	._:

	xor ebx, ebx
	xor ecx, ecx
	mov bx, word [rdi + Shard.pos + Point.x + 2]
	mov cx, word [rdi + Shard.pos + Point.y + 2]

	mov edx, [rdi + Shard.radius] ; circle radius

	call screen_drawCircle

	xor eax, eax
	pop r8
	pop rcx
	pop rbx
	ret


%endif
