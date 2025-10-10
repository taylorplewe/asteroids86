ifndef asteroids_h
asteroids_h = 1

include <common.s>
include <screen.s>
include <bullets.s>


Asteroid struct
	pos       Point  <?> ; 16.16 fixed point
	velocity  Vector <?> ; 16.16 fixed point
	mass      dd     ?   ; 0 when dead ; 'size' is a reserved word
	shape_ptr dq     ?
	rot       db     ?
	rot_speed db     ?
Asteroid ends

MAX_NUM_ASTEROIDS = 64


.data

asteroids Asteroid MAX_NUM_ASTEROIDS dup (<>)
asteroids_current_points Point 2 dup (<?>) ; for drawing

asteroid_shapes FatPtr {asteroid_shape1, asteroid_shape1_len}, {asteroid_shape2, asteroid_shape2_len}, {asteroid_shape3, asteroid_shape3_len}

asteroid_shape1 BasePoint {48, 08h}, {48, 1eh}, {35, 28h}, {42, 42h}, {48, 58h}, {30, 72h}, {40, 87h}, {46, 9eh}, {32, 0bch}, {43, 0c5h}, {46, 0deh}, {37, 0eeh}
asteroid_shape1_len = ($ - asteroid_shape1) / BasePoint

asteroid_shape2 BasePoint {30, 00h}, {40, 1eh}, {48, 37h}, {44, 53h}, {32, 68h}, {48, 78h}, {49, 8dh}, {46, 0a6h}, {32, 0bbh}, {43, 0c5h}, {49, 0e0h}, {46, 0f4h}
asteroid_shape2_len = ($ - asteroid_shape2) / BasePoint

asteroid_shape3 BasePoint {48, 10h}, {39, 20h}, {54, 33h}, {35, 41h}, {46, 60h}, {32, 73h}, {45, 88h}, {46, 0a8h}, {28, 0c6h}, {43, 0c6h}, {51, 0e0h}, {35, 0e8h}
asteroid_shape3_len = ($ - asteroid_shape3) / BasePoint

ASTEROID_MASS1 = 16
ASTEROID_MASS2 = 32
ASTEROID_MASS3 = 50
asteroid_masses dd 0, ASTEROID_MASS1, ASTEROID_MASS2, ASTEROID_MASS3
asteroid_r_squareds dd 0, ASTEROID_MASS1*ASTEROID_MASS1, ASTEROID_MASS2*ASTEROID_MASS2, ASTEROID_MASS3*ASTEROID_MASS3


.code

asteroids_test proc
	mov [asteroids].Asteroid.pos.x, (SCREEN_WIDTH/2) shl 16
	mov [asteroids].Asteroid.pos.y, (SCREEN_HEIGHT/2) shl 16
	mov [asteroids].Asteroid.mass, 3
	mov [asteroids].Asteroid.rot, 0
	mov [asteroids].Asteroid.rot_speed, 1
	mov [asteroids].Asteroid.velocity.x, 00002000h
	mov [asteroids].Asteroid.velocity.y, 00008000h
	lea rax, asteroid_shapes
	mov [asteroids].Asteroid.shape_ptr, rax

	mov [asteroids + sizeof Asteroid].Asteroid.pos.x, (100) shl 16
	mov [asteroids + sizeof Asteroid].Asteroid.pos.y, (20) shl 16
	mov [asteroids + sizeof Asteroid].Asteroid.mass, 3
	mov [asteroids + sizeof Asteroid].Asteroid.rot, 0
	mov [asteroids + sizeof Asteroid].Asteroid.velocity.x, 00010000h
	mov [asteroids + sizeof Asteroid].Asteroid.velocity.y, -00008000h
	lea rax, asteroid_shapes + sizeof FatPtr*2
	mov [asteroids + sizeof Asteroid].Asteroid.shape_ptr, rax

	ret
asteroids_test endp

; in:
	; rdi - pointer to current asteroid
asteroids_checkBullets macro
	local mainLoop
	local _next

	mov ecx, NUM_BULLETS
	lea rsi, bullets
	mainLoop:
		cmp [rsi].Bullet.ticks_to_live, 0
		je _next
	
		; check if bullet is inside this asteroid's circular hitbox, dictacted by it's 'mass'
		; hit if (dx^2 + dy^2) <= r^2
		mov ax, word ptr [rsi].Bullet.pos.x + 2
		sub ax, word ptr [rdi].Asteroid.pos.x + 2
		imul eax, eax
		mov r8d, eax
		mov ax, word ptr [rsi].Bullet.pos.y + 2
		sub ax, word ptr [rdi].Asteroid.pos.y + 2
		imul eax, eax
		mov r9d, eax

		add r8d, r9d
		lea r9, asteroid_r_squareds
		mov ebx, [rdi].Asteroid.mass
		shl ebx, 2 ; dwords
		cmp r8d, [r9 + rbx]
		jg _next

		; hit!
		mov [rdi].Asteroid.mass, 0
		jmp next

		_next:
		add rsi, sizeof Bullet
		loop mainLoop
endm

asteroids_updateAll proc
	mov edx, MAX_NUM_ASTEROIDS
	lea rdi, asteroids
	mainLoop:
		cmp [rdi].Asteroid.mass, 0
		je next

		; rotate asteroid
		mov al, [rdi].Asteroid.rot_speed
		add [rdi].Asteroid.rot, al

		; move asteroid
		mov eax, [rdi].Asteroid.velocity.x
		add [rdi].Asteroid.pos.x, eax
		mov eax, [rdi].Asteroid.velocity.y
		add [rdi].Asteroid.pos.y, eax

		; wrap position
		lea rsi, [rdi].Asteroid.pos
		call wrapPointAroundScreen

		; asteroids_checkBullets
		mov ecx, NUM_BULLETS
		lea rsi, bullets
		_mainLoop:
			cmp [rsi].Bullet.ticks_to_live, 0
			je _next
	
			; check if bullet is inside this asteroid's circular hitbox, dictacted by it's 'mass'
			; hit if (dx^2 + dy^2) <= r^2
			mov ax, word ptr [rsi].Bullet.pos.x + 2
			sub ax, word ptr [rdi].Asteroid.pos.x + 2
			cwde
			imul eax, eax
			mov r8d, eax
			mov ax, word ptr [rsi].Bullet.pos.y + 2
			sub ax, word ptr [rdi].Asteroid.pos.y + 2
			cwde
			imul eax, eax
			mov r9d, eax

			add r8d, r9d
			lea r9, asteroid_r_squareds
			mov ebx, [rdi].Asteroid.mass
			shl ebx, 2 ; dwords
			cmp r8d, [r9 + rbx]
			jg _next

			; hit!
			mov [rdi].Asteroid.mass, 0
			mov [rsi].Bullet.ticks_to_live, 0
			jmp next

			_next:
			add rsi, sizeof Bullet
			loop _mainLoop

		push rdi
		push rdx
		call asteroids_draw
		pop rdx
		pop rdi

		next:
		add rdi, sizeof Asteroid
		dec edx
		jne mainLoop
	ret
asteroids_updateAll endp

; in:
	; rdi - pointer to current asteroid
asteroids_draw proc
	; draw all the points of this asteroid's shape
	mov rax, [rdi].Asteroid.shape_ptr
	mov ecx, [rax].FatPtr.len
	mov r8, [rax].FatPtr.pntr
	mov rsi, r8
	mainLoop:
		lea r10, [rdi].Asteroid.pos
		mov r11b, [rdi].Asteroid.rot
		push rcx
		lea r9, asteroids_current_points
		call applyBasePointToPoint
		pop rcx

		add r8, sizeof BasePoint
		cmp rcx, 1
		cmove r8, rsi ; on the last one, wrap back to first point to finish the shape

		push rcx
		lea r9, asteroids_current_points + sizeof Point
		call applyBasePointToPoint
		pop rcx

		push rdi
		push rcx
		push r8
		mov r8d, [fg_color]
		screen_mDrawLine asteroids_current_points, asteroids_current_points + sizeof Point
		pop r8
		pop rcx
		pop rdi

		next:
		loop mainLoop
	ret
asteroids_draw endp


endif
