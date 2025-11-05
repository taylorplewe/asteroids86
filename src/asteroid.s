%ifndef asteroid_h
%define asteroid_h

%include "src/globaldefs.inc"

%include "src/common.s"
%include "src/array.s"
%include "src/fx/shard.s"
%include "src/screen.s"
%include "src/bullet.s"
%include "src/ufo.s"
%include "src/ship.s"


struc Asteroid
	pos       Point  <?> ; 16.16 fixed point
	velocity  Vector <?> ; 16.16 fixed point
	mass      dd     ?   ; 0 when dead ; 'size' is a reserved word
	shape_ptr dq     ?
	dir       db     ?   ; which way this asteroid is flying, in 256-based radians
	rot       db     ?
	rot_speed db     ?
endstruc

MAX_NUM_ASTEROIDS equ 64


.data

asteroids_arr           Array    { { asteroids, 0 }, MAX_NUM_ASTEROIDS, sizeof Asteroid }

asteroid_shapes FatPtr {asteroid_shape1, asteroid_shape1_len}, {asteroid_shape2, asteroid_shape2_len}, {asteroid_shape3, asteroid_shape3_len}
asteroid_shapes_end:

asteroid_shape1 BasePoint {48, 08h}, {48, 1eh}, {35, 28h}, {42, 42h}, {48, 58h}, {30, 72h}, {40, 87h}, {46, 9eh}, {32, 0bch}, {43, 0c5h}, {46, 0deh}, {37, 0eeh}
asteroid_shape1_len equ ($ - asteroid_shape1) / BasePoint

asteroid_shape2 BasePoint {30, 00h}, {40, 1eh}, {48, 37h}, {44, 53h}, {32, 68h}, {48, 78h}, {49, 8dh}, {46, 0a6h}, {32, 0bbh}, {43, 0c5h}, {49, 0e0h}, {46, 0f4h}
asteroid_shape2_len equ ($ - asteroid_shape2) / BasePoint

asteroid_shape3 BasePoint {48, 10h}, {39, 20h}, {54, 33h}, {35, 41h}, {46, 60h}, {32, 73h}, {45, 88h}, {46, 0a8h}, {28, 0c6h}, {43, 0c6h}, {51, 0e0h}, {35, 0e8h}
asteroid_shape3_len equ ($ - asteroid_shape3) / BasePoint

ASTEROID_MASS1 equ 32
ASTEROID_MASS2 equ 50
ASTEROID_MASS3 equ 70
ASTEROID_MASS4 equ 75 ; for checking collision in a bigger area
asteroid_masses       dd 0, ASTEROID_MASS1,                ASTEROID_MASS2,                ASTEROID_MASS3
asteroid_r_squareds   dd 0, ASTEROID_MASS1*ASTEROID_MASS1, ASTEROID_MASS2*ASTEROID_MASS2, ASTEROID_MASS3*ASTEROID_MASS3, ASTEROID_MASS4*ASTEROID_MASS4
asteroid_mass_factors dd 0, 00008000h,                     00010000h,                     00018000h
asteroid_speed_shifts db 0, 2,                             1,                             0
asteroid_score_adds   dd 0, 100,                           50,                            20


.data?

asteroids               Asteroid MAX_NUM_ASTEROIDS dup (<>)
asteroid_current_points Point    2                 dup (<?>) ; for drawing


.code

; in:
	; rsi  - pointer to asteroid
	; r10b - asteroid's dir
asteroid_setVelocity proc
	push rcx

	mov ecx, 1
	call getVelocityFromRotAndSpeed
	mov qword ptr [rsi].Asteroid.velocity, rax

	; smaller asteroids double their velocity a few times
	mov ecx, [rsi].Asteroid.mass
	lea rax, asteroid_speed_shifts
	add rax, rcx
	mov cl, byte ptr [rax]
	shl [rsi].Asteroid.velocity.x, cl
	shl [rsi].Asteroid.velocity.y, cl

	pop rcx
	ret
asteroid_setVelocity endp

; in:
	; rbx  - pos
	; ecx  - mass
	; rdi  - shape_ptr
	; r10b - dir (will be used for its velocity as well)
	; r9b  - rot_speed
asteroid_create proc
	push rsi

	lea rsi, asteroids_arr
	call array_push
	test rax, rax
	je _end

	mov rsi, rax

	mov qword ptr [rsi].Asteroid.pos, rbx
	mov [rsi].Asteroid.mass, ecx
	mov [rsi].Asteroid.shape_ptr, rdi
	mov [rsi].Asteroid.dir, r10b
	mov [rsi].Asteroid.rot_speed, r9b

	call asteroid_setVelocity

	_end:
	pop rsi
	ret
asteroid_create endp

; in:
	; ecx - mass
	; rdi - shape ptr
asteroid_createRand proc
	push rbx
	push r9
	push r10

	call getRandomOnscreenFixedPointPos
	mov rbx, rax
	
	; rot_speed
	rand r9d
	mov r10b, r9b
	shr r9d, 8 ; ensure rot_speed is unrelated to rot
	and r9d, 1

	call asteroid_create

	pop r10
	pop r9
	pop rbx
	ret
asteroid_createRand endp

; in:
	; rdi - pointer to asteroid
asteroid_addToScore proc
	push rsi

	; add to score
	mov eax, [rdi].Asteroid.mass
	shl eax, 2
	lea rsi, asteroid_score_adds
	mov eax, dword ptr [rsi + rax]
	add [score], eax

	pop rsi
	ret
asteroid_addToScore endp

; If this asteroid has a mass greater than 1, destroy this asteroid and spawn 2 smaller ones in its place.
; Otherwise, just destroy it.
; in:
	; rdi - pointer to asteroid just hit
asteroid_onHit proc
	push rbx
	push rcx
	push rsi
	push rdi
	push r9
	push r10

	; create burst of dust
	mov rbx, qword ptr [rdi].Asteroid.pos
	mov rcx, qword ptr [rdi].Asteroid.velocity
	call shard_createBurst

	cmp [rdi].Asteroid.mass, 1
	je destroy

	xor r10, r10

	dec [rdi].Asteroid.mass
	add [rdi].Asteroid.rot_speed, 1
	; replace this asteroid with a smaller one...
	add [rdi].Asteroid.shape_ptr, sizeof FatPtr
	lea rax, asteroid_shapes_end
	cmp [rdi].Asteroid.shape_ptr, rax
	jb @f
	lea rax, asteroid_shapes
	mov [rdi].Asteroid.shape_ptr, rax
	@@:

	; (set velocity of that one)
	sub [rdi].Asteroid.dir, 20
	mov r10b, [rdi].Asteroid.dir
	mov rsi, rdi
	call asteroid_setVelocity

	; ...and then add another one
	mov rbx, qword ptr [rdi].Asteroid.pos
	mov ecx, [rdi].Asteroid.mass
	add r10b, 40
	mov r9b, [rdi].Asteroid.rot_speed
	mov rdi, [rdi].Asteroid.shape_ptr
	; replace this asteroid with a smaller one...
	add rdi, sizeof FatPtr
	lea rax, asteroid_shapes_end
	cmp rdi, rax
	jb @f
	lea rax, asteroid_shapes
	mov rdi, rax
	@@:
	call asteroid_create

	jmp _end

	destroy:
	lea rsi, asteroids_arr
	call array_removeEl

	_end:
	pop r10
	pop r9
	pop rdi
	pop rsi
	pop rcx
	pop rbx
	ret
asteroid_onHit endp

; in:
	; rdi - pointer to current asteroid
; out:
	; eax - 1 if hit, 0 else
asteroid_checkBullets proc
	push rbx
	push rcx
	push rsi
	push r8
	push r9

	mov eax, [bullets_arr].Array.data.len
	test eax, eax
	je noHit
	xor ecx, ecx
	lea rsi, bullets
	mainLoop:
		; check if bullet is inside this asteroid's circular hitbox, dictacted by it's 'mass'
		; hit if (dx^2 + dy^2) <= r^2
		xor eax, eax ; clear upper bits
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
		jg next

		; hit!
		push rsi
		lea rsi, bullets_arr
		mov eax, ecx
		call array_removeAt
		pop rsi
		cmp [rsi].Bullet.is_evil, 0
		jne @f
			call asteroid_addToScore
		@@:
		call asteroid_onHit
		mov eax, 1
		jmp _end

		next:
		add rsi, sizeof Bullet
		inc ecx
		cmp ecx, [bullets_arr].Array.data.len
		jb mainLoop

	noHit:
	xor eax, eax
	_end:
	pop r9
	pop r8
	pop rsi
	pop rcx
	pop rbx
	ret
asteroid_checkBullets endp

; in:
	; rdi - pointer to current asteroid
; out:
	; eax - 1 if hit, 0 else
asteroid_checkUfos proc
	push rbx
	push rcx
	push rsi
	push r8
	push r9

	mov eax, [ufos_arr].Array.data.len
	test eax, eax
	je noHit
	xor ecx, ecx
	lea rsi, ufos
	mainLoop:
		; check if bullet is inside this asteroid's circular hitbox, dictacted by it's 'mass'
		; hit if (dx^2 + dy^2) <= r^2
		xor eax, eax ; clear upper bits
		mov ax, word ptr [rsi].Ufo.pos.x + 2
		sub ax, word ptr [rdi].Asteroid.pos.x + 2
		cwde
		imul eax, eax
		mov r8d, eax
		mov ax, word ptr [rsi].Ufo.pos.y + 2
		sub ax, word ptr [rdi].Asteroid.pos.y + 2
		cwde
		imul eax, eax
		mov r9d, eax

		add r8d, r9d
		lea r9, asteroid_r_squareds
		mov ebx, [rdi].Asteroid.mass
		shl ebx, 2 ; dwords
		cmp r8d, [r9 + rbx]
		jg next

		; hit!
		push rdi
		mov rdi, rsi
		call ufo_destroy
		pop rdi
		call asteroid_onHit
		mov eax, 1
		jmp _end

		next:
		add rsi, sizeof Ufo
		inc ecx
		cmp ecx, [ufos_arr].Array.data.len
		jb mainLoop

	noHit:
	xor eax, eax
	_end:
	pop r9
	pop r8
	pop rsi
	pop rcx
	pop rbx
	ret
asteroid_checkUfos endp

; in:
	; rdi - pointer to Asteroid
	; rbx - Asteroid's mass (this is a param so you could check for bigger radii if you wanted)
; out:
	; eax - 0 if no collision, -1 otherwise
asteroid_checkShip proc
	push rbx
	push r8
	push r9

	; hit if (dx^2 + dy^2) <= r^2
	xor eax, eax ; clear upper bits
	mov ax, word ptr [ship].x + 2
	sub ax, word ptr [rdi].Asteroid.pos.x + 2
	cwde
	imul eax, eax
	mov r8d, eax
	mov ax, word ptr [ship].y + 2
	sub ax, word ptr [rdi].Asteroid.pos.y + 2
	cwde
	imul eax, eax
	mov r9d, eax

	add r8d, r9d
	lea r9, asteroid_r_squareds
	shl ebx, 2 ; dwords
	xor eax, eax
	cmp r8d, [r9 + rbx]
	setg al
	dec eax ; -1 if hit, 0 else

	pop r9
	pop r8
	pop rbx
	ret
asteroid_checkShip endp

; Check for collision with ship, destroy it if so
asteroid_checkAndDestroyShip proc
	cmp [ship].respawn_counter, 0
	jne noHit
	cmp [is_in_gameover], 0
	jne noHit
	cmp [num_flashes_left], 0
	jne noHit
	cmp [ship_num_flashes_left], 0
	jne noHit
	jmp check
	noHit:
		xor eax, eax
		ret
	check:

	push rbx
	mov ebx, [rdi].Asteroid.mass
	call asteroid_checkShip
	pop rbx
	test eax, eax
	je _end

	; hit!
	call ship_destroy
	call asteroid_addToScore
	call asteroid_onHit
	mov eax, 1

	_end:
	ret
asteroid_checkAndDestroyShip endp

asteroid_updateAll proc
	lea rsi, asteroids_arr
	lea r8, asteroid_update
	jmp array_forEach
asteroid_updateAll endp

; Callback routine
; in:
	; rdi - pointer to asteroid
; out:
	; eax - 1 if asteroid was deleted, 0 otherwise
asteroid_update proc
	push rsi

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

	call asteroid_checkBullets ; returns 1 if hit, 0 else
	test eax, eax
	jne _end
	call asteroid_checkUfos    ; returns 1 if hit, 0 else
	test eax, eax
	jne _end
	call asteroid_checkAndDestroyShip    ; returns 1 if hit, 0 else

	_end:
	pop rsi
	ret
asteroid_update endp

asteroid_drawAll proc
	lea rsi, asteroids_arr
	lea r8, asteroid_draw
	jmp array_forEach
asteroid_drawAll endp

; in:
	; rdi - pointer to current asteroid
; out:
	; eax - 0 (asteroid not destroyed)
asteroid_draw proc
	push rcx
	push rsi
	push r8
	push r12

	; for shrinking the asteroids based on their mass
	lea r12, asteroid_mass_factors
	mov eax, [rdi].Asteroid.mass
	shl eax, 2 ; dwords
	mov r12d, [r12 + rax]
	; draw all the points of this asteroid's shape
	mov rax, [rdi].Asteroid.shape_ptr
	mov ecx, [rax].FatPtr.len
	mov r8, [rax].FatPtr.pntr
	mov rsi, r8
	_loop:
		lea r10, [rdi].Asteroid.pos
		mov r11b, [rdi].Asteroid.rot
		lea r9, asteroid_current_points
		push rcx
		call applyBasePointToPoint
		pop rcx

		add r8, sizeof BasePoint
		cmp rcx, 1
		cmove r8, rsi ; on the last one, wrap back to first point to finish the shape

		lea r9, asteroid_current_points + sizeof Point
		push rcx
		call applyBasePointToPoint
		pop rcx

		push rdi
		push rcx
		push r8
		mov r8d, [flash_color]
		screen_mDrawLine asteroid_current_points, asteroid_current_points + sizeof Point
		pop r8
		pop rcx
		pop rdi

		next:
		loop _loop

	pop r12
	pop r8
	pop rsi
	pop rcx
	xor eax, eax
	ret
asteroid_draw endp


%endif