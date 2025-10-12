ifndef asteroid_h
asteroid_h = 1

include <globaldefs.inc>
include <common.s>
include <screen.s>
include <bullet.s>


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

asteroids                Asteroid  MAX_NUM_ASTEROIDS dup (<>)
asteroids_len            dd        0
asteroid_current_points Point     2                 dup (<?>) ; for drawing

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


.code

asteroid_test proc
	; rax - pos
	; ebx - mass
	; rsi - shape_ptr
	; r8b - rot (will be used for its velocity as well)
	; r9b - rot_speed
	mov rax, ((SCREEN_HEIGHT/2) shl 48) or ((SCREEN_WIDTH/2) shl 16)
	mov ebx, 3
	lea rsi, asteroid_shapes
	xor r8, r8
	mov r9, 1
	call asteroid_create

	mov rax, ((20) shl 48) or ((100) shl 16)
	mov ebx, 3
	lea rsi, asteroid_shapes + sizeof FatPtr
	xor r8, r8
	xor r9, r9
	call asteroid_create

	mov rax, ((200) shl 48) or ((900) shl 16)
	mov ebx, 3
	lea rsi, asteroid_shapes + sizeof FatPtr*2
	mov r8, 50
	xor r9, r9
	call asteroid_create

	ret
asteroid_test endp

; in:
	; rax - pos
	; ebx - mass
	; rsi - shape_ptr
	; r8b - rot (will be used for its velocity as well)
	; r9b - rot_speed
asteroid_create proc
	mov ecx, [asteroids_len]
	cmp ecx, MAX_NUM_ASTEROIDS
	jge _end

	inc [asteroids_len]
	imul ecx, sizeof Asteroid

	lea rdi, asteroids
	mov qword ptr [rdi + rcx].Asteroid.pos, rax
	mov [rdi + rcx].Asteroid.mass, ebx
	mov [rdi + rcx].Asteroid.shape_ptr, rsi
	mov [rdi + rcx].Asteroid.rot, r8b
	mov [rdi + rcx].Asteroid.rot_speed, r9b

	xor eax, eax ; clear upper bits
	mov al, r8b
	call sin
	sar rax, 15
	mov [rdi + rcx].Asteroid.velocity.x, eax

	xor rax, rax
	mov al, r8b
	call cos
	sar rax, 15
	mov [rdi + rcx].Asteroid.velocity.y, eax

	_end:
	ret
asteroid_create endp

; If this asteroid has a mass greater than 1, destroy this asteroid and spawn 2 smaller ones in its place.
; Otherwise, just destroy it.
; in:
	; rdi - pointer to asteroid just hit
asteroid_onHitByBullet proc
	cmp [rdi].Asteroid.mass, 1
	je destroy

	; replace this asteroid with a smaller one...
	dec [rdi].Asteroid.mass
	add [rdi].Asteroid.shape_ptr, sizeof FatPtr
	lea rax, asteroid_shapes_end
	cmp [rdi].Asteroid.shape_ptr, rax
	jb @f
	lea rax, asteroid_shapes
	mov [rdi].Asteroid.shape_ptr, rax
	@@:
	shl [rdi].Asteroid.velocity.x, 1
	shl [rdi].Asteroid.velocity.y, 1
	add [rdi].Asteroid.rot_speed, 1

	; ...and then add another one
	jmp _end

	destroy:
	call asteroid_destroy

	_end:
	ret
asteroid_onHitByBullet endp

; in:
	; rdi - pointer to current asteroid
; out:
	; eax - 1 if hit, 0 else
asteroid_checkBullets proc
	push rsi
	push rcx
	push rbx
	push r8
	push r9

	cmp [bullets_len], 0
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
		mov eax, ecx
		call bullet_destroy
		call asteroid_onHitByBullet
		mov eax, 1
		jmp _end

		next:
		add rsi, sizeof Bullet
		inc ecx
		cmp ecx, [bullets_len]
		jb mainLoop

	noHit:
	xor eax, eax
	_end:
	pop r9
	pop r8
	pop rbx
	pop rcx
	pop rsi
	ret
asteroid_checkBullets endp

asteroid_updateAll proc
	cmp [asteroids_len], 0
	je _end
	xor edx, edx
	lea rdi, asteroids
	mainLoop:
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

		call asteroid_checkBullets
		test eax, eax
		jne nextCmp

		push rdi
		push rdx
		call asteroid_draw
		pop rdx
		pop rdi

		next:
		add rdi, sizeof Asteroid
		inc edx
		nextCmp:
		cmp edx, [asteroids_len]
		jb mainLoop
	_end:
	ret
asteroid_updateAll endp

; in:
	; rdi - pointer to asteroid to destroy
asteroid_destroy proc
	push rsi
	push rcx

	dec [asteroids_len]
	je _end

	; move the last element in the list to this newly opened up one
	mov eax, [asteroids_len]
	imul eax, sizeof Asteroid
	lea rsi, asteroids
	add rsi, rax

	mov ecx, sizeof Asteroid
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
	ret
asteroid_destroy endp

; in:
	; rdi - pointer to current asteroid
asteroid_draw proc
	; for shrinking the asteroids based on their mass
	lea r12, asteroid_mass_factors
	mov eax, [rdi].Asteroid.mass
	shl eax, 2
	mov r12d, [r12 + rax]
	; draw all the points of this asteroid's shape
	mov rax, [rdi].Asteroid.shape_ptr
	mov ecx, [rax].FatPtr.len
	mov r8, [rax].FatPtr.pntr
	mov rsi, r8
	mainLoop:
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
		dec ecx
		jne mainLoop
	ret
asteroid_draw endp


endif
