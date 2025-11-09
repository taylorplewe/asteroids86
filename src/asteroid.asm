%ifndef asteroid_h
%define asteroid_h

%include "src/globaldefs.inc"

%include "src/common.asm"
%include "src/array.asm"
%include "src/fx/shard.asm"
%include "src/screen.asm"
%include "src/bullet.asm"
%include "src/ufo.asm"
%include "src/ship.asm"


struc Asteroid
	.pos:       resb Point_size ; 16.16 fixed point
	.velocity:  resb Vector_size ; 16.16 fixed point
	.mass:      resd     1   ; 0 when dead ; 'size' is a reserved word
	.shape_ptr: resq     1
	.dir:       resb     1   ; which way this asteroid is flying, in 256-based radians
	.rot:       resb     1
	.rot_speed: resb     1
endstruc

MAX_NUM_ASTEROIDS equ 64


section .data

asteroids_arr:
	istruc Array
		istruc FatPtr
			at .pntr, dq asteroids
			at .len, dd 0
		iend
		at .cap, dd MAX_NUM_ASTEROIDS
		at .el_size, dd Asteroid_size
	iend

asteroid_shapes:
	istruc FatPtr
		at .pntr, dq asteroid_shape1
		at .len, dd asteroid_shape1_len
	iend
	istruc FatPtr
		at .pntr, dq asteroid_shape2
		at .len, dd asteroid_shape2_len
	iend
	istruc FatPtr
		at .pntr, dq asteroid_shape3
		at .len, dd asteroid_shape3_len
	iend
asteroid_shapes_end:

asteroid_shape1:
	istruc BasePoint
		at .vec, dd 48
		at .rad, db 08h
	iend
	istruc BasePoint
		at .vec, dd 48
		at .rad, db 1eh
	iend
	istruc BasePoint
		at .vec, dd 35
		at .rad, db 28h
	iend
	istruc BasePoint
		at .vec, dd 42
		at .rad, db 42h
	iend
	istruc BasePoint
		at .vec, dd 48
		at .rad, db 58h
	iend
	istruc BasePoint
		at .vec, dd 30
		at .rad, db 72h
	iend
	istruc BasePoint
		at .vec, dd 40
		at .rad, db 87h
	iend
	istruc BasePoint
		at .vec, dd 46
		at .rad, db 9eh
	iend
	istruc BasePoint
		at .vec, dd 32
		at .rad, db 0bch
	iend
	istruc BasePoint
		at .vec, dd 43
		at .rad, db 0c5h
	iend
	istruc BasePoint
		at .vec, dd 46
		at .rad, db 0deh
	iend
	istruc BasePoint
		at .vec, dd 37
		at .rad, db 0eeh
	iend
asteroid_shape1_len equ ($ - asteroid_shape1) / BasePoint_size

asteroid_shape2:
	istruc BasePoint
		at .vec, dd 30
		at .rad, db 00h
	iend
	istruc BasePoint
		at .vec, dd 40
		at .rad, db 1eh
	iend
	istruc BasePoint
		at .vec, dd 48
		at .rad, db 37h
	iend
	istruc BasePoint
		at .vec, dd 44
		at .rad, db 53h
	iend
	istruc BasePoint
		at .vec, dd 32
		at .rad, db 68h
	iend
	istruc BasePoint
		at .vec, dd 48
		at .rad, db 78h
	iend
	istruc BasePoint
		at .vec, dd 49
		at .rad, db 8dh
	iend
	istruc BasePoint
		at .vec, dd 46
		at .rad, db 0a6h
	iend
	istruc BasePoint
		at .vec, dd 32
		at .rad, db 0bbh
	iend
	istruc BasePoint
		at .vec, dd 43
		at .rad, db 0c5h
	iend
	istruc BasePoint
		at .vec, dd 49
		at .rad, db 0e0h
	iend
	istruc BasePoint
		at .vec, dd 46
		at .rad, db 0f4h
	iend
asteroid_shape2_len equ ($ - asteroid_shape2) / BasePoint_size

asteroid_shape3:
	istruc BasePoint
		at .vec, dd 48
		at .rad, db 10h
	iend
	istruc BasePoint
		at .vec, dd 39
		at .rad, db 20h
	iend
	istruc BasePoint
		at .vec, dd 54
		at .rad, db 33h
	iend
	istruc BasePoint
		at .vec, dd 35
		at .rad, db 41h
	iend
	istruc BasePoint
		at .vec, dd 46
		at .rad, db 60h
	iend
	istruc BasePoint
		at .vec, dd 32
		at .rad, db 73h
	iend
	istruc BasePoint
		at .vec, dd 45
		at .rad, db 88h
	iend
	istruc BasePoint
		at .vec, dd 46
		at .rad, db 0a8h
	iend
	istruc BasePoint
		at .vec, dd 28
		at .rad, db 0c6h
	iend
	istruc BasePoint
		at .vec, dd 43
		at .rad, db 0c6h
	iend
	istruc BasePoint
		at .vec, dd 51
		at .rad, db 0e0h
	iend
	istruc BasePoint
		at .vec, dd 35
		at .rad, db 0e8h
	iend
asteroid_shape3_len equ ($ - asteroid_shape3) / BasePoint_size

ASTEROID_MASS1 equ 32
ASTEROID_MASS2 equ 50
ASTEROID_MASS3 equ 70
ASTEROID_MASS4 equ 75 ; for checking collision in a bigger area
asteroid_masses       dd 0, ASTEROID_MASS1,                ASTEROID_MASS2,                ASTEROID_MASS3
asteroid_r_squareds   dd 0, ASTEROID_MASS1*ASTEROID_MASS1, ASTEROID_MASS2*ASTEROID_MASS2, ASTEROID_MASS3*ASTEROID_MASS3, ASTEROID_MASS4*ASTEROID_MASS4
asteroid_mass_factors dd 0, 00008000h,                     00010000h,                     00018000h
asteroid_speed_shifts db 0, 2,                             1,                             0
asteroid_score_adds   dd 0, 100,                           50,                            20


section .bss

asteroids               resb Asteroid_size * MAX_NUM_ASTEROIDS
asteroid_current_points resb Point_size *    2 ; for drawing


section .text

; in:
	; rsi  - pointer to asteroid
	; r10b - asteroid's dir
asteroid_setVelocity:
	push rcx

	mov ecx, 1
	call getVelocityFromRotAndSpeed
	mov qword [rsi + Asteroid.velocity], rax

	; smaller asteroids double their velocity a few times
	mov ecx, [rsi + Asteroid.mass]
	lea rax, asteroid_speed_shifts
	add rax, rcx
	mov cl, byte [rax]
	shl [rsi + Asteroid.velocity + Point.x], cl
	shl [rsi + Asteroid.velocity + Point.y], cl

	pop rcx
	ret


; in:
	; rbx  - pos
	; ecx  - mass
	; rdi  - shape_ptr
	; r10b - dir (will be used for its velocity as well)
	; r9b  - rot_speed
asteroid_create:
	push rsi

	lea rsi, asteroids_arr
	call array_push
	test rax, rax
	je .end

	mov rsi, rax

	mov qword [rsi + Asteroid.pos], rbx
	mov [rsi + Asteroid.mass], ecx
	mov [rsi + Asteroid.shape_ptr], rdi
	mov [rsi + Asteroid.dir], r10b
	mov [rsi + Asteroid.rot_speed], r9b

	call asteroid_setVelocity

	.end:
	pop rsi
	ret


; in:
	; ecx - mass
	; rdi - shape ptr
asteroid_createRand:
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


; in:
	; rdi - pointer to asteroid
asteroid_addToScore:
	push rsi

	; add to score
	mov eax, [rdi + Asteroid.mass]
	shl eax, 2
	lea rsi, asteroid_score_adds
	mov eax, dword [rsi + rax]
	add [score], eax

	pop rsi
	ret


; If this asteroid has a mass greater than 1, destroy this asteroid and spawn 2 smaller ones in its place.
; Otherwise, just destroy it.
; in:
	; rdi - pointer to asteroid just hit
asteroid_onHit:
	push rbx
	push rcx
	push rsi
	push rdi
	push r9
	push r10

	; create burst of dust
	mov rbx, qword [rdi + Asteroid.pos]
	mov rcx, qword [rdi + Asteroid.velocity]
	call shard_createBurst

	cmp dword [rdi + Asteroid.mass], 1
	je .destroy

	xor r10, r10

	dec dword [rdi + Asteroid.mass]
	add byte [rdi + Asteroid.rot_speed], 1
	; replace this asteroid with a smaller one...
	add qword [rdi + Asteroid.shape_ptr], FatPtr_size
	lea rax, asteroid_shapes_end
	cmp [rdi + Asteroid.shape_ptr], rax
	jb ._
	lea rax, asteroid_shapes
	mov [rdi + Asteroid.shape_ptr], rax
	._:

	; (set velocity of that one)
	sub byte [rdi + Asteroid.dir], 20
	mov r10b, [rdi + Asteroid.dir]
	mov rsi, rdi
	call asteroid_setVelocity

	; ...and then add another one
	mov rbx, qword [rdi + Asteroid.pos]
	mov ecx, [rdi + Asteroid.mass]
	add r10b, 40
	mov r9b, [rdi + Asteroid.rot_speed]
	mov rdi, [rdi + Asteroid.shape_ptr]
	; replace this asteroid with a smaller one...
	add rdi, FatPtr_size
	lea rax, asteroid_shapes_end
	cmp rdi, rax
	jb ._1
	lea rax, asteroid_shapes
	mov rdi, rax
	._1:
	call asteroid_create

	jmp .end

	.destroy:
	lea rsi, asteroids_arr
	call array_removeEl

	.end:
	pop r10
	pop r9
	pop rdi
	pop rsi
	pop rcx
	pop rbx
	ret


; in:
	; rdi - pointer to current asteroid
; out:
	; eax - 1 if hit, 0 else
asteroid_checkBullets:
	push rbx
	push rcx
	push rsi
	push r8
	push r9

	mov eax, [bullets_arr + Array.data + FatPtr.len]
	test eax, eax
	je .noHit
	xor ecx, ecx
	lea rsi, bullets
	.mainLoop:
		; check if bullet is inside this asteroid's circular hitbox, dictacted by it's 'mass'
		; hit if (dx^2 + dy^2) <= r^2
		xor eax, eax ; clear upper bits
		mov ax, word [rsi + Bullet.pos + Point.x + 2]
		sub ax, word [rdi + Asteroid.pos + Point.x + 2]
		cwde
		imul eax, eax
		mov r8d, eax
		mov ax, word [rsi + Bullet.pos + Point.y + 2]
		sub ax, word [rdi + Asteroid.pos + Point.y + 2]
		cwde
		imul eax, eax
		mov r9d, eax

		add r8d, r9d
		lea r9, asteroid_r_squareds
		mov ebx, [rdi + Asteroid.mass]
		shl ebx, 2 ; dwords
		cmp r8d, [r9 + rbx]
		jg .next

		; hit!
		push rsi
		lea rsi, bullets_arr
		mov eax, ecx
		call array_removeAt
		pop rsi
		cmp dword [rsi + Bullet.is_evil], 0
		jne ._
			call asteroid_addToScore
		._:
		call asteroid_onHit
		mov eax, 1
		jmp .end

		.next:
		add rsi, Bullet_size
		inc ecx
		cmp ecx, [bullets_arr + Array.data + FatPtr.len]
		jb .mainLoop

	.noHit:
	xor eax, eax
	.end:
	pop r9
	pop r8
	pop rsi
	pop rcx
	pop rbx
	ret


; in:
	; rdi - pointer to current asteroid
; out:
	; eax - 1 if hit, 0 else
asteroid_checkUfos:
	push rbx
	push rcx
	push rsi
	push r8
	push r9

	mov eax, [ufos_arr + Array.data + FatPtr.len]
	test eax, eax
	je .noHit
	xor ecx, ecx
	lea rsi, ufos
	.mainLoop:
		; check if bullet is inside this asteroid's circular hitbox, dictacted by it's 'mass'
		; hit if (dx^2 + dy^2) <= r^2
		xor eax, eax ; clear upper bits
		mov ax, word [rsi + Ufo.pos + Point.x + 2]
		sub ax, word [rdi + Asteroid.pos + Point.x + 2]
		cwde
		imul eax, eax
		mov r8d, eax
		mov ax, word [rsi + Ufo.pos + Point.y + 2]
		sub ax, word [rdi + Asteroid.pos + Point.y + 2]
		cwde
		imul eax, eax
		mov r9d, eax

		add r8d, r9d
		lea r9, asteroid_r_squareds
		mov ebx, [rdi + Asteroid.mass]
		shl ebx, 2 ; dwords
		cmp r8d, [r9 + rbx]
		jg .next

		; hit!
		push rdi
		mov rdi, rsi
		call ufo_destroy
		pop rdi
		call asteroid_onHit
		mov eax, 1
		jmp .end

		.next:
		add rsi, Ufo_size
		inc ecx
		cmp ecx, [ufos_arr + Array.data + FatPtr.len]
		jb .mainLoop

	.noHit:
	xor eax, eax
	.end:
	pop r9
	pop r8
	pop rsi
	pop rcx
	pop rbx
	ret


; in:
	; rdi - pointer to Asteroid
	; rbx - Asteroid's mass (this is a param so you could check for bigger radii if you wanted)
; out:
	; eax - 0 if no collision, -1 otherwise
asteroid_checkShip:
	push rbx
	push r8
	push r9

	; hit if (dx^2 + dy^2) <= r^2
	xor eax, eax ; clear upper bits
	mov ax, word [ship + Point.x + 2]
	sub ax, word [rdi + Asteroid.pos + Point.x + 2]
	cwde
	imul eax, eax
	mov r8d, eax
	mov ax, word [ship + Point.y + 2]
	sub ax, word [rdi + Asteroid.pos + Point.y + 2]
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


; Check for collision with ship, destroy it if so
asteroid_checkAndDestroyShip:
	cmp dword [ship + Ship.respawn_counter], 0
	jne .noHit
	cmp dword [is_in_gameover], 0
	jne .noHit
	cmp dword [num_flashes_left], 0
	jne .noHit
	cmp dword [ship_num_flashes_left], 0
	jne .noHit
	jmp .check
	.noHit:
		xor eax, eax
		ret
	.check:

	push rbx
	mov ebx, [rdi + Asteroid.mass]
	call asteroid_checkShip
	pop rbx
	test eax, eax
	je .end

	; hit!
	call ship_destroy
	call asteroid_addToScore
	call asteroid_onHit
	mov eax, 1

	.end:
	ret


asteroid_updateAll:
	lea rsi, asteroids_arr
	lea r8, asteroid_update
	jmp array_forEach


; Callback routine
; in:
	; rdi - pointer to asteroid
; out:
	; eax - 1 if asteroid was deleted, 0 otherwise
asteroid_update:
	push rsi

	; rotate asteroid
	mov al, [rdi + Asteroid.rot_speed]
	add [rdi + Asteroid.rot], al

	; move asteroid
	mov eax, [rdi + Asteroid.velocity + Point.x]
	add [rdi + Asteroid.pos + Point.x], eax
	mov eax, [rdi + Asteroid.velocity + Point.y]
	add [rdi + Asteroid.pos + Point.y], eax

	; wrap position
	lea rsi, [rdi + Asteroid.pos]
	call wrapPointAroundScreen

	call asteroid_checkBullets ; returns 1 if hit, 0 else
	test eax, eax
	jne .end
	call asteroid_checkUfos    ; returns 1 if hit, 0 else
	test eax, eax
	jne .end
	call asteroid_checkAndDestroyShip    ; returns 1 if hit, 0 else

	.end:
	pop rsi
	ret


asteroid_drawAll:
	lea rsi, asteroids_arr
	lea r8, asteroid_draw
	jmp array_forEach


; in:
	; rdi - pointer to current asteroid
; out:
	; eax - 0 (asteroid not destroyed)
asteroid_draw:
	push rcx
	push rsi
	push r8
	push r12

	; for shrinking the asteroids based on their mass
	lea r12, asteroid_mass_factors
	mov eax, [rdi + Asteroid.mass]
	shl eax, 2 ; dwords
	mov r12d, [r12 + rax]
	; draw all the points of this asteroid's shape
	mov rax, [rdi + Asteroid.shape_ptr]
	mov ecx, [rax + FatPtr.len]
	mov r8, [rax + FatPtr.pntr]
	mov rsi, r8
	.loop:
		lea r10, [rdi + Asteroid.pos]
		mov r11b, [rdi + Asteroid.rot]
		lea r9, asteroid_current_points
		push rcx
		call applyBasePointToPoint
		pop rcx

		add r8, BasePoint_size
		cmp rcx, 1
		cmove r8, rsi ; on the last one, wrap back to first point to finish the shape

		lea r9, asteroid_current_points + Point_size
		push rcx
		call applyBasePointToPoint
		pop rcx

		push rdi
		push rcx
		push r8
		mov r8d, [flash_color]
		screen_mDrawLine asteroid_current_points, asteroid_current_points + Point_size
		pop r8
		pop rcx
		pop rdi

		.next:
		loop .loop

	pop r12
	pop r8
	pop rsi
	pop rcx
	xor eax, eax
	ret



%endif