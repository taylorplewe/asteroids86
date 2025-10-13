ifndef bullet_h
bullet_h = 1

include <globaldefs.inc>

include <common.s>
include <global.s>
include <array.s>
include <screen.s>


Bullet struct
	pos           Point  <?> ; 16.16 fixed point x and y
	velocity      Vector <?> ; 16.16 fixed point x and y
	ticks_to_live dd ?
Bullet ends

NUM_BULLETS          = 6
BULLET_SPEED         = 10
BULLET_TICKS_TO_LIVE = 70


.data

bullets     Bullet NUM_BULLETS dup (<>)
bullets_arr Array  { { bullets, 0 }, NUM_BULLETS, sizeof Bullet }


.code

; in:
	; r8d - X 16.16 fixed point
	; r9d - Y 16.16 fixed point
	; r10b - rotation in 256-based radians
bullet_create proc
	lea rsi, bullets_arr
	call array_push
	test rax, rax
	je _end

	mov rsi, rax
	mov [rsi].Bullet.ticks_to_live, BULLET_TICKS_TO_LIVE
	mov [rsi].Bullet.pos.x, r8d
	mov [rsi].Bullet.pos.y, r9d

	xor eax, eax
	mov al, r10b
	call sin
	cdqe
	imul rax, BULLET_SPEED
	sar rax, 15
	mov [rsi].Bullet.velocity.x, eax

	xor eax, eax
	mov al, r10b
	call cos
	cdqe
	imul rax, BULLET_SPEED
	sar rax, 15
	mov [rsi].Bullet.velocity.y, eax

	_end:
	ret
bullet_create endp

bullet_updateAll proc
	lea rsi, bullets_arr
	lea r8, bullet_update
	jmp array_forEach
bullet_updateAll endp

; Callback function
; in:
	; rdi - pointer to bullet
; out:
	; eax - 1 if bullet was deleted, 0 otherwise
bullet_update proc
	push rsi

	mov eax, [rdi].Bullet.velocity.x
	add [rdi].Bullet.pos.x, eax
	mov eax, [rdi].Bullet.velocity.y
	sub [rdi].Bullet.pos.y, eax

	; wrap around screen
	lea rsi, [rdi].Bullet.pos
	call wrapPointAroundScreen

	dec [rdi].Bullet.ticks_to_live
	jne normalEnd

	; destroy bullet
	mov eax, ecx
	lea rsi, bullets_arr
	call array_removeAt
	mov eax, 1
	jmp _end

	normalEnd:
	xor eax, eax

	_end:
	pop rsi
	ret
bullet_update endp

bullet_drawAll proc
	mov r14d, SCREEN_WIDTH
	mov r15d, SCREEN_HEIGHT

	lea rsi, bullets_arr
	lea r8, bullet_draw
	jmp array_forEach
bullet_drawAll endp

; Callback routine
; in:
	; rdi - pointer to bullet
; out:
	; eax - 0
bullet_draw proc
	push rdi
	push r8
	push rcx
	push rbx

	xor ebx, ebx ; clear upper bits
	xor ecx, ecx ; clear upper bits
	mov bx, word ptr [rdi].Bullet.pos.x + 2
	mov cx, word ptr [rdi].Bullet.pos.y + 2

	lea rdi, pixels
	mov r8d, [fg_color]

	screen_drawCircle

	pop rbx
	pop rcx
	pop r8
	pop rdi

	xor eax, eax
	ret
bullet_draw endp


endif
