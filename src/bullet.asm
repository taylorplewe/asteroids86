%ifndef bullet_h
%define bullet_h

%include "src/globaldefs.inc"

%include "src/common.asm"
%include "src/global.asm"
%include "src/array.asm"
%include "src/screen.asm"


struc Bullet
	.pos:           resb Point_size ; 16.16 fixed point x and y
	.velocity:      resb Vector_size ; 16.16 fixed point x and y
	.ticks_to_live: resd 1
	.is_evil:       resd 1
endstruc

NUM_BULLETS          equ 5
BULLET_SPEED         equ 10
BULLET_TICKS_TO_LIVE equ 60


section .data

; bullets_arr Array { { bullets, 0 }, NUM_BULLETS, Bullet_size }
bullets_arr:
	istruc Array
		istruc FatPtr
			at .pntr, dq bullets
			at .len, dd 0
		iend
		at .cap, dd NUM_BULLETS
		at .el_size, dd Bullet_size
	iend


section .bss

bullets: resb Bullet_size * NUM_BULLETS


section .text

; in:
	; r8d  - X 16.16 fixed point
	; r9d  - Y 16.16 fixed point
	; r10b - rotation in 256-based radians
	; r11  - is_evil
bullet_create:
	push rcx
	push rsi

	lea rsi, bullets_arr
	call array_push
	test rax, rax
	je .end

	mov rsi, rax
	mov [rsi + Bullet.ticks_to_live], BULLET_TICKS_TO_LIVE
	mov [rsi + Bullet.pos.x], r8d
	mov [rsi + Bullet.pos.y], r9d
	mov [rsi + Bullet.is_evil], r11d

	mov ecx, BULLET_SPEED
	call getVelocityFromRotAndSpeed
	mov qword [rsi + Bullet.velocity], rax

	.end:
	pop rsi
	pop rcx
	ret


bullet_updateAll:
	lea rsi, bullets_arr
	lea r8, bullet_update
	jmp array_forEach


; Callback routine
; in:
	; rdi - pointer to bullet
; out:
	; eax - 1 if bullet was deleted, 0 otherwise
bullet_update:
	push rsi

	mov eax, [rdi + Bullet.velocity.x]
	add [rdi + Bullet.pos.x], eax
	mov eax, [rdi + Bullet.velocity.y]
	sub [rdi + Bullet.pos.y], eax

	; wrap around screen
	lea rsi, [rdi + Bullet.pos]
	call wrapPointAroundScreen

	dec [rdi + Bullet.ticks_to_live]
	jne .normalEnd

	; destroy bullet
	mov eax, ecx
	lea rsi, bullets_arr
	call array_removeAt
	mov eax, 1
	jmp .end

	.normalEnd:
	xor eax, eax

	.end:
	pop rsi
	ret


bullet_drawAll:
	mov r14d, SCREEN_WIDTH
	mov r15d, SCREEN_HEIGHT

	lea rsi, bullets_arr
	lea r8, bullet_draw
	jmp array_forEach


; Callback routine
; in:
	; rdi - pointer to bullet
; out:
	; eax - 0
bullet_draw:
	push rbx
	push rcx
	push r8

	xor ebx, ebx ; clear upper bits
	xor ecx, ecx ; clear upper bits
	mov bx, word [rdi + Bullet.pos.x + 2]
	mov cx, word [rdi + Bullet.pos.y + 2]

	cmp [rdi + Bullet.is_evil], 0
	je ._
		mov r8d, [evil_color]
		jmp .decideColorEnd
	._:
		mov r8d, [fg_color]
	.decideColorEnd:

	mov edx, 4

	call screen_drawCircle

	xor eax, eax ; bullet was not destroyed
	pop r8
	pop rcx
	pop rbx
	ret



%endif
