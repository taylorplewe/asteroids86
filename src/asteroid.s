ifndef asteroid_h
asteroid_h = 1

include <globaldefs.inc>

include <common.s>
include <array.s>
include <fx\shard.s>
include <screen.s>
include <bullet.s>


Asteroid struct
	pos       Point  <?> ; 16.16 fixed point
	velocity  Vector <?> ; 16.16 fixed point
	mass      dd     ?   ; 0 when dead ; 'size' is a reserved word
	shape_ptr dq     ?
	dir       db     ?   ; which way this asteroid is flying, in 256-based radians
	rot       db     ?
	rot_speed db     ?
Asteroid ends

MAX_NUM_ASTEROIDS = 64


.data

asteroids                Asteroid  MAX_NUM_ASTEROIDS dup (<>)
asteroids_arr            Array     { { asteroids, 0 }, MAX_NUM_ASTEROIDS, sizeof Asteroid }
asteroid_current_points  Point     2                 dup (<?>) ; for drawing

asteroid_shapes FatPtr {asteroid_shape1, asteroid_shape1_len}, {asteroid_shape2, asteroid_shape2_len}, {asteroid_shape3, asteroid_shape3_len}
asteroid_shapes_end:

asteroid_shape1 BasePoint {48, 08h}, {48, 1eh}, {35, 28h}, {42, 42h}, {48, 58h}, {30, 72h}, {40, 87h}, {46, 9eh}, {32, 0bch}, {43, 0c5h}, {46, 0deh}, {37, 0eeh}
asteroid_shape1_len = ($ - asteroid_shape1) / BasePoint

asteroid_shape2 BasePoint {30, 00h}, {40, 1eh}, {48, 37h}, {44, 53h}, {32, 68h}, {48, 78h}, {49, 8dh}, {46, 0a6h}, {32, 0bbh}, {43, 0c5h}, {49, 0e0h}, {46, 0f4h}
asteroid_shape2_len = ($ - asteroid_shape2) / BasePoint

asteroid_shape3 BasePoint {48, 10h}, {39, 20h}, {54, 33h}, {35, 41h}, {46, 60h}, {32, 73h}, {45, 88h}, {46, 0a8h}, {28, 0c6h}, {43, 0c6h}, {51, 0e0h}, {35, 0e8h}
asteroid_shape3_len = ($ - asteroid_shape3) / BasePoint

ASTEROID_MASS1 = 32
ASTEROID_MASS2 = 50
ASTEROID_MASS3 = 70
asteroid_masses       dd 0, ASTEROID_MASS1,                ASTEROID_MASS2,                ASTEROID_MASS3
asteroid_r_squareds   dd 0, ASTEROID_MASS1*ASTEROID_MASS1, ASTEROID_MASS2*ASTEROID_MASS2, ASTEROID_MASS3*ASTEROID_MASS3
asteroid_mass_factors dd 0, 00008000h,                     00010000h,                     00018000h
asteroid_speed_shifts db 0, 2,                             1,                             0


.code

asteroid_test proc
	; rax - pos
	; ebx - mass
	; rsi - shape_ptr
	; r8b - rot (will be used for its velocity as well)
	; r9b - rot_speed
	mov rbx, ((20) shl 48) or ((900) shl 16)
	mov ecx, 3
	lea rdi, asteroid_shapes
	mov r8, -5
	mov r9, 1
	call asteroid_create

	mov rbx, ((20) shl 48) or ((100) shl 16)
	mov ecx, 3
	lea rdi, asteroid_shapes + sizeof FatPtr
	xor r8, r8
	xor r9, r9
	call asteroid_create

	mov rbx, ((200) shl 48) or ((900) shl 16)
	mov ecx, 3
	lea rdi, asteroid_shapes + sizeof FatPtr*2
	mov r8, 50
	xor r9, r9
	call asteroid_create

	ret
asteroid_test endp

; in:
	; rsi - pointer to asteroid
	; r8b - asteroid's dir
asteroid_setVelocity proc
	push rcx

	xor eax, eax ; clear upper bits
	mov al, r8b
	call sin
	sar eax, 15
	mov [rsi].Asteroid.velocity.x, eax

	xor rax, rax
	mov al, r8b
	call cos
	sar eax, 15
	neg eax
	mov [rsi].Asteroid.velocity.y, eax

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
	; rbx - pos
	; ecx - mass
	; rdi - shape_ptr
	; r8b - dir (will be used for its velocity as well)
	; r9b - rot_speed
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
	mov [rsi].Asteroid.dir, r8b
	mov [rsi].Asteroid.rot_speed, r9b

	call asteroid_setVelocity

	_end:
	pop rsi
	ret
asteroid_create endp

; If this asteroid has a mass greater than 1, destroy this asteroid and spawn 2 smaller ones in its place.
; Otherwise, just destroy it.
; in:
	; rdi - pointer to asteroid just hit
asteroid_onHit proc
	push rbx
	push rcx
	push rsi
	push rdi
	push r8
	push r9

	mov rbx, qword ptr [rdi].Asteroid.pos
	mov rcx, qword ptr [rdi].Asteroid.velocity
	call shard_createBurst

	cmp [rdi].Asteroid.mass, 1
	je destroy

	xor r8, r8

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
	mov r8b, [rdi].Asteroid.dir
	mov rsi, rdi
	call asteroid_setVelocity

	; ...and then add another one
	mov rbx, qword ptr [rdi].Asteroid.pos
	mov ecx, [rdi].Asteroid.mass
	add r8b, 40
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
	pop r9
	pop r8
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
	; bullets_arr.data.len is NOT zero here hwen it should be
	cmp [bullets_arr].Array.data.len, 0
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

; Check for collision with ship, destroy it if so
asteroid_checkShip proc
	cmp [ship].ticks_to_respawn, 0
	je @f
		xor eax, eax
		ret
	@@:

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
	mov ebx, [rdi].Asteroid.mass
	shl ebx, 2 ; dwords
	cmp r8d, [r9 + rbx]
	jle hit
	xor eax, eax
	jmp _end

	hit:
	call ship_destroy
	call asteroid_onHit
	mov eax, 1

	_end:
	pop r9
	pop r8
	pop rbx
	ret
asteroid_checkShip endp

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
	call asteroid_checkShip

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
		mov r8d, [fg_color]
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


endif