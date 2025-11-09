%ifndef shipShard_h
%define shipShard_h

%include "src/globaldefs.inc"

%include "src/common.asm"
%include "src/array.asm"


struc ShipShard
	.pos:           resb Point_size ; 16.16 fixed point
	.velocity:      resb Vector_size ; 16.16 fixed point
	.len:           resd     1
	.rot:           resw     1   ; 8.8 fixed point
	.rot_velocity:  resw     1   ; 8.8 fixed point
	.ticks_to_live: resd 1
endstruc

MAX_NUM_SHIP_SHARDS          equ 64
SHIP_SHARD_MIN_TICKS_TO_LIVE equ 120
SHIP_SHARD_VELOCITY_DIFF     equ 24000h


section .data

; ship_shards_arr Array { { ship_shards, 0 }, MAX_NUM_SHIP_SHARDS, ShipShard_size }
ship_shards_arr:
	istruc Array
		istruc FatPtr
			at .pntr, dq ship_shards
			at .len, dd 0
		iend
		at .cap, dd MAX_NUM_SHIP_SHARDS
		at .el_size, dd ShipShard_size
	iend


section .bss

ship_shards: resb ShipShard_size * MAX_NUM_SHIP_SHARDS


section .text

; in:
	; rbx - pos
	; rcx - velocity
	; edx - len
	; r8b - rotation added to base velocity to fly in
shipShard_create:
	push rsi

	lea rsi, ship_shards_arr
	call array_push
	test eax, eax
	je .end

	mov rsi, rax
	mov qword [rsi + ShipShard.pos], rbx
	mov qword [rsi + ShipShard.velocity], rcx
	sar [rsi + ShipShard.velocity + Point.x], 2
	sar [rsi + ShipShard.velocity + Point.y], 2
	mov [rsi + ShipShard.len], edx

	; randomize values
	xor eax, eax
	rand eax
	mov [rsi + ShipShard.rot], ax
	sar eax, 16 + 5 ; upper word of eax, then "and" it with 00000111.11111111b (but signed)
	mov [rsi + ShipShard.rot_velocity], ax

	; ticks_to_live = also random
	rdrand eax
	and eax, 64 - 1 ; 0 - 64 (just over one second)
	add eax, SHIP_SHARD_MIN_TICKS_TO_LIVE
	mov [rsi + ShipShard.ticks_to_live], eax

	; apply velocity rotation
	; x
	xor eax, eax
	mov al, r8b
	call sin
	cdqe
	imul rax, SHIP_SHARD_VELOCITY_DIFF
	sar rax, 32
	add [rsi + ShipShard.velocity + Point.x], eax
	; y
	xor eax, eax
	mov al, r8b
	call cos
	cdqe
	imul rax, SHIP_SHARD_VELOCITY_DIFF
	sar rax, 32
	sub [rsi + ShipShard.velocity + Point.y], eax
	
	.end:
	pop rsi
	ret


shipShard_updateAll:
	lea rsi, ship_shards_arr
	lea r8, shipShard_update
	jmp array_forEach


; in:
	; rdi - pointer to ship shard
; out:
	; eax - 1 if ship shard is destroyed, 0 else
shipShard_update:
	push rsi

	dec [rdi + ShipShard.ticks_to_live]
	jne ._
		; destroy it
		lea rsi, ship_shards_arr
		call array_removeEl
		mov eax, 1
		jmp .end
	._:

	; rotate shard
	xor eax, eax
	mov ax, [rdi + ShipShard.rot_velocity]
	add [rdi + ShipShard.rot], ax

	; move shard
	; TODO: might be able to do this with 64-bit SIMD vectors?
	mov eax, [rdi + ShipShard.velocity + Point.x]
	add [rdi + ShipShard.pos + Point.x], eax
	mov eax, [rdi + ShipShard.velocity + Point.y]
	add [rdi + ShipShard.pos + Point.y], eax

	lea rsi, [rdi + ShipShard.pos]
	call wrapPointAroundScreen

	xor eax, eax
	.end:
	pop rsi
	ret


shipShard_drawAll:
	mov r14d, SCREEN_WIDTH
	mov r15d, SCREEN_HEIGHT

	lea rsi, ship_shards_arr
	lea r8, shipShard_draw
	jmp array_forEach


; in:
	; rdi - pointer to ship shard
; out:
	; eax - 0 (ship shard not destroyed)
shipShard_draw:
	push rbx
	push rcx
	push rsi
	push rdi
	push r8

	; x
	xor eax, eax
	mov al, byte [rdi + ShipShard.rot + 1]
	call sin
	cdqe
	mov ebx, [rdi + ShipShard.len]
	imul rax, rbx
	sar rax, 32
	; p1
	xor ebx, ebx
	mov bx, word [rdi + ShipShard.pos + Point.x + 2]
	add ebx, eax
	mov [screen_point1 + Point.x], ebx
	test ebx, ebx
	; p2
	xor ebx, ebx
	mov bx, word [rdi + ShipShard.pos + Point.x + 2]
	sub ebx, eax
	mov [screen_point2 + Point.x], ebx
	test ebx, ebx
	; y
	xor eax, eax
	mov al, byte [rdi + ShipShard.rot + 1]
	call cos
	cdqe
	mov ebx, [rdi + ShipShard.len]
	imul rax, rbx
	sar rax, 32
	; p1
	xor ebx, ebx
	mov bx, word [rdi + ShipShard.pos + Point.y + 2]
	add ebx, eax
	mov [screen_point1 + Point.y], ebx
	; p2
	xor ebx, ebx
	mov bx, word [rdi + ShipShard.pos + Point.y + 2]
	sub ebx, eax
	mov [screen_point2 + Point.y], ebx

	mov r8d, [fg_color]

	; fade out
	mov ebx, [rdi + ShipShard.ticks_to_live]
	cmp ebx, 32
	jge ._
		shl ebx, 24 + 3
		and ebx, 0ff000000h
		and r8d, 00ffffffh
		or r8d, ebx
	._:

	call screen_drawLine

	xor eax, eax
	pop r8
	pop rdi
	pop rsi
	pop rcx
	pop rbx
	ret



%endif
