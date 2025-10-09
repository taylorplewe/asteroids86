Asteroid struct
	pos       Point  <?> ; 16.16 fixed point
	velocity  Vector <?> ; 16.16 fixed point
	mass      dd     ?   ; 0 when dead
	shape_ptr dq     ?
	rot       db     ?
Asteroid ends

MAX_NUM_ASTEROIDS       = 64


.data

asteroids Asteroid MAX_NUM_ASTEROIDS dup (<>)
asteroids_current_points Point 2 dup (<?>) ; for drawing

asteroid_shapes FatPtr {asteroid_shape1, asteroid_shape1_len}

asteroid_shape1 BasePoint {32, 00h}, {32, 40h}, {32, 80h}, {32, 0c0h}
asteroid_shape1_len = ($ - asteroid_shape1) / BasePoint


.code

asteroids_test proc
	mov [asteroids].Asteroid.pos.x, (SCREEN_WIDTH/2) shl 16
	mov [asteroids].Asteroid.pos.y, (SCREEN_HEIGHT/2) shl 16
	mov [asteroids].Asteroid.mass, 1
	mov [asteroids].Asteroid.rot, 0
	mov [asteroids].Asteroid.velocity.x, 00002000h
	mov [asteroids].Asteroid.velocity.y, 00008000h
	lea rax, asteroid_shapes
	mov [asteroids].Asteroid.shape_ptr, rax

	mov [asteroids + sizeof Asteroid].Asteroid.pos.x, (100) shl 16
	mov [asteroids + sizeof Asteroid].Asteroid.pos.y, (20) shl 16
	mov [asteroids + sizeof Asteroid].Asteroid.mass, 1
	mov [asteroids + sizeof Asteroid].Asteroid.rot, 50
	mov [asteroids + sizeof Asteroid].Asteroid.velocity.x, 00010000h
	mov [asteroids + sizeof Asteroid].Asteroid.velocity.y, -00008000h
	lea rax, asteroid_shapes
	mov [asteroids + sizeof Asteroid].Asteroid.shape_ptr, rax

	ret
asteroids_test endp

asteroids_updateAll proc
	mov ecx, MAX_NUM_ASTEROIDS
	lea rdi, asteroids
	mainLoop:
		cmp [rdi].Asteroid.mass, 0
		je next

		; move asteroid
		mov eax, [rdi].Asteroid.velocity.x
		add [rdi].Asteroid.pos.x, eax
		mov eax, [rdi].Asteroid.velocity.y
		add [rdi].Asteroid.pos.y, eax

		; wrap position
		lea rsi, [rdi].Asteroid.pos
		call wrapPointAroundScreen

		push rdi
		push rcx
		call asteroids_draw
		pop rcx
		pop rdi

		next:
		add rdi, sizeof Asteroid
		loop mainLoop
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
