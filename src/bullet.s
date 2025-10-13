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
bullets_arr Array  { { bullets, 0 }, NUM_BULLETS }


.code

; in:
	; r8d - X 16.16 fixed point
	; r9d - Y 16.16 fixed point
	; r10b - rotation in 256-based radians
bullet_create proc
	mov ecx, [bullets_len]
	cmp ecx, NUM_BULLETS
	jge _end

	inc [bullets_len]
	imul ecx, sizeof Bullet

	lea rdi, bullets
	mov [rdi + rcx].Bullet.ticks_to_live, BULLET_TICKS_TO_LIVE
	mov [rdi + rcx].Bullet.pos.x, r8d
	mov [rdi + rcx].Bullet.pos.y, r9d

	xor rax, rax
	mov al, r10b
	call sin
	cdqe
	imul rax, BULLET_SPEED
	sar rax, 15
	mov [rdi + rcx].Bullet.velocity.x, eax

	xor rax, rax
	mov al, r10b
	call cos
	cdqe
	imul rax, BULLET_SPEED
	sar rax, 15
	mov [rdi + rcx].Bullet.velocity.y, eax

	_end:
	ret
bullet_create endp

; in:
	; eax - index to delete
bullet_destroy proc
	push rdi
	push rsi
	push rcx

	dec [bullets_len]
	je _end

	imul eax, sizeof Bullet
	lea rdi, bullets
	add rdi, rax

	mov eax, [bullets_len]
	imul eax, sizeof Bullet
	lea rsi, bullets
	add rsi, rax

	mov ecx, sizeof Bullet
	xor eax, eax
	copyLoop:
		mov al, [rsi]
		mov [rdi], al
		inc rsi
		inc rdi
		loop copyLoop

	_end:
	pop rcx
	pop rsi
	pop rdi
	ret
bullet_destroy endp

bullet_updateAll proc
	lea rdi, bullets
	cmp [bullets_len], 0
	je _end
	xor ecx, ecx
	mainLoop:
		mov eax, [rdi].Bullet.velocity.x
		add [rdi].Bullet.pos.x, eax
		mov eax, [rdi].Bullet.velocity.y
		sub [rdi].Bullet.pos.y, eax

		; wrap around screen
		lea rsi, [rdi].Bullet.pos
		call wrapPointAroundScreen

		dec [rdi].Bullet.ticks_to_live
		jne @f
		; destroy bullet
		mov eax, ecx
		call bullet_destroy
		jmp nextCmp
		@@:
		
		add rdi, sizeof Bullet
		inc ecx
		nextCmp:
		cmp ecx, [bullets_len]
		jl mainLoop

	_end:
	ret
bullet_updateAll endp

bullet_drawAll proc
	mov r14d, SCREEN_WIDTH
	mov r15d, SCREEN_HEIGHT

	lea rdi, bullets
	cmp [bullets_len], 0
	je _end
	xor ecx, ecx
	mainLoop:
		call bullet_draw

		add rdi, sizeof Bullet
		inc ecx
		nextCmp:
		cmp ecx, [bullets_len]
		jl mainLoop

	_end:
	ret
bullet_drawAll endp

; in:
	; rdi - pointer to bullet
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

	ret
bullet_draw endp


endif
