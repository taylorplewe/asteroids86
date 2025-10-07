Bullet struct
	pos      Point <?>  ; 16.16 fixed point x and y
	velocity Vector <?> ; 16.16 fixed point x and y
	exists   dd ?
Bullet ends

NUM_BULLETS = 64
BULLET_SPEED = 8


.data

bullets Bullet NUM_BULLETS dup (<>)


.code

; in:
	; r8d - X 16.16 fixed point
	; r9d - Y 16.16 fixed point
	; r10b - rotation in 256-based radians
bullets_createBullet proc
	; find an empty spot
	lea rdi, bullets
	xor ecx, ecx
	mainLoop:
		mov eax, [rdi].Bullet.exists
		test eax, eax
		jne next

		inc [rdi].Bullet.exists
		mov [rdi].Bullet.pos.x, r8d
		mov [rdi].Bullet.pos.y, r9d

		xor rax, rax
		mov al, r10b
		call sin
		cdqe
		imul rax, BULLET_SPEED
		sar rax, 15
		mov [rdi].Bullet.velocity.x, eax

		xor rax, rax
		mov al, r10b
		call cos
		cdqe
		imul rax, BULLET_SPEED
		sar rax, 15
		mov [rdi].Bullet.velocity.y, eax
		jmp _end
		
		next:
		add rdi, sizeof Bullet
		inc ecx
		cmp ecx, NUM_BULLETS
		jl mainLoop

		; no empty spaces!

	_end:
	ret
bullets_createBullet endp

bullets_updateAll proc
	lea rdi, bullets
	xor ecx, ecx
	mainLoop:
		mov eax, [rdi].Bullet.exists
		test eax, eax
		je next

		mov eax, [rdi].Bullet.velocity.x
		add [rdi].Bullet.pos.x, eax
		mov eax, [rdi].Bullet.velocity.y
		sub [rdi].Bullet.pos.y, eax

		; bounds check
		mov eax, [rdi].Bullet.pos.x
		sar eax, 16
		test eax, eax
		js destroyBullet		
		cmp eax, SCREEN_WIDTH
		jg destroyBullet

		mov eax, [rdi].Bullet.pos.y
		sar eax, 16
		test eax, eax
		js destroyBullet		
		cmp eax, SCREEN_HEIGHT
		jg destroyBullet
		jmp renderBullet
		
		destroyBullet:
		xor eax, eax
		mov [rdi].Bullet.exists, eax
		jmp next
		renderBullet:
		call bullets_draw
		
		next:
		add rdi, sizeof Bullet
		inc ecx
		cmp ecx, NUM_BULLETS
		jl mainLoop

	ret
bullets_updateAll endp

; in:
	; rdi - pointer to bullet
bullets_draw proc
	mov eax, [rdi].Bullet.pos.x
	shr eax, 16
	mov [screen_point1].x, eax
	mov eax, [rdi].Bullet.pos.y
	shr eax, 16
	mov [screen_point1].y, eax
	mov r8d, [fg_color]
	push rdi
	call screen_drawPoint
	pop rdi

	ret
bullets_draw endp
