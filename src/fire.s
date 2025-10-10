ifndef fire_h
fire_h = 1

include <screen.s>


FIRE_VELOCITY       = 1
FIRE_MAX_NUM_FRAMES = 30
MAX_NUM_FIRES       = 64


.data

Fire struct
	is_alive         dd     ?
	num_frames_alive dd     ?
	p1               Point  <?> ; 16.16 fixed point
	p2               Point  <?> ; 16.16 fixed point
    shrink_vec       Vector <?> ; p1 will ADD this value to get towards the center, p2 will SUBTRACT
	rot              db     ?
Fire ends
fires Fire MAX_NUM_FIRES dup (<?>)
fire_color Pixel <0ffh, 0, 0, 0ffh>


.code

; in:
	; rdi - pointer to fire
fire_draw macro
	; color
	mov r8d, [fire_color]
	and r8d, 000000ffh
	mov eax, [rdi].Fire.num_frames_alive
	mov ebx, FIRE_MAX_NUM_FRAMES
	mov ecx, ebx
	mov r9d, ebx
	mov edx, eax
	mov r10d, eax

	; alpha
	sub ebx, eax
	add ebx, 15
	; mov ebx, 0ffffffffh
	shl ebx, 24 + 2
	or r8d, ebx

	; green
	shl edx, 1
	cmp edx, ecx
	jg @f
	sub ecx, edx
	add ecx, 15
	shl ecx, 8 + 2
	or r8d, ecx
	@@:

	; blue
	shl r10d, 2
	cmp r10d, r9d
	jg @f
	sub r9d, r10d
	add r9d, 15
	shl r9d, 16 + 2
	or r8d, r9d
	@@:

	mov ax, word ptr [rdi].Fire.p1.x + 2
	cwde
	mov [screen_point1].x, eax
	mov ax, word ptr [rdi].Fire.p1.y + 2
	cwde
	mov [screen_point1].y, eax
	mov ax, word ptr [rdi].Fire.p2.x + 2
	cwde
	mov [screen_point2].x, eax
	mov ax, word ptr [rdi].Fire.p2.y + 2
	cwde
	mov [screen_point2].y, eax

	call screen_drawLine
endm

; in:
	; r8  - point1 (as qword ptr)
	; r10 - point2 (as qword ptr)
	; al  - rotation in 256-based radians
fire_create proc
	; look for empty spot
	lea rdi, fires
	mov ecx, MAX_NUM_FIRES
	mainLoop:
		cmp [rdi].Fire.is_alive, 0
		jne next

		inc [rdi].Fire.is_alive
		mov [rdi].Fire.rot, al
		mov [rdi].Fire.num_frames_alive, 0
		mov qword ptr [rdi].Fire.p1, r8
		mov qword ptr [rdi].Fire.p2, r10

		mov r9, r8
		shr r9, 32
		mov r11, r10
		shr r11, 32
		; r8d  = p1.x
		; r9d  = p1.y
		; r10d = p2.x
		; r11d = p2.y

		; calculate center point
		; x
			cmp r8d, r10d
			jg p1xGreater
			p2xGreater:
				mov eax, r10d
				mov ebx, r8d
				jmp xCenterFinish
			p1xGreater:
				mov eax, r8d
				mov ebx, r10d
			xCenterFinish:
			sub eax, ebx
			shr eax, 1 ; /2
			add ebx, eax
			mov r12d, ebx
		; y
			cmp r9d, r11d
			jg p1yGreater
			p2yGreater:
				mov eax, r11d
				mov ebx, r9d
				jmp yCenterFinish
			p1yGreater:
				mov eax, r9d
				mov ebx, r11d
			yCenterFinish:
			sub eax, ebx
			shr eax, 1 ; /2
			add ebx, eax
			mov r13d, ebx
		; r12d = center.x
		; r13d = center.y

		; calculate amount to shrink every frame
		; x
			mov eax, r12d
			sub eax, r8d
			mov ebx, FIRE_MAX_NUM_FRAMES
			cdq
			idiv ebx
			mov [rdi].Fire.shrink_vec.x, eax
		; y
			mov eax, r13d
			sub eax, r9d
			mov ebx, FIRE_MAX_NUM_FRAMES
			cdq
			idiv ebx
			mov [rdi].Fire.shrink_vec.y, eax
		
		jmp _end

		next:
		add rdi, sizeof Fire
		dec ecx
		jne mainLoop ; can't do LOOP instruction since that requires a rel8 jump
	_end:
	ret
fire_create endp

fire_updateAll proc
	lea rdi, fires
	mov ecx, MAX_NUM_FIRES
	mainLoop:
		cmp [rdi].Fire.is_alive, 0
		je next

		inc [rdi].Fire.num_frames_alive
		cmp [rdi].Fire.num_frames_alive, FIRE_MAX_NUM_FRAMES
		jl @f
        	; destroy fire
			mov [rdi].Fire.is_alive, 0
			jmp next
		@@:

		; move fire
		; x
		xor rax, rax
		mov al, [rdi].Fire.rot
		call sin
		cdqe
		imul rax, FIRE_VELOCITY
		sar rax, 15
		add [rdi].Fire.p1.x, eax
		add [rdi].Fire.p2.x, eax
		; y
		xor rax, rax
		mov al, [rdi].Fire.rot
		call cos
		cdqe
		imul rax, FIRE_VELOCITY
		sar rax, 15
		neg eax
		add [rdi].Fire.p1.y, eax
		add [rdi].Fire.p2.y, eax

		; shrink fire
		mov eax, [rdi].Fire.shrink_vec.x
		add [rdi].Fire.p1.x, eax
		sub [rdi].Fire.p2.x, eax
		mov eax, [rdi].Fire.shrink_vec.y
		add [rdi].Fire.p1.y, eax
		sub [rdi].Fire.p2.y, eax

		push rcx
		push rdi
		fire_draw
		pop rdi
		pop rcx

		next:
		add rdi, sizeof Fire
		dec ecx
		jne mainLoop ; too far for LOOP instruction
	ret
fire_updateAll endp


endif
