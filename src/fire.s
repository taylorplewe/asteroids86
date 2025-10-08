; fire effect

FIRE_MAX_NUM_FRAMES = 30
MAX_NUM_FIRES       = 64

.data

Fire struct
	is_alive         dd    ?
	p1               Point <?> ; 16.16 fixed point
	p2               Point <?> ; 16.16 fixed point
        shrink_vec       Vector <?> ; p1 will ADD this value to get towards the center, p2 will SUBTRACT
	num_frames_alive dd    ?
Fire ends
fires Fire MAX_NUM_FIRES dup (<?>)
fire_color Pixel <0ffh, 0, 0, 0ffh>


.code

; in:
	; rdi - pointer to fire
fire_draw macro
	mov r8d, [fire_color]
	and r8d, 00ffffffh
	mov eax, [rdi].Fire.num_frames_alive
	mov ebx, FIRE_MAX_NUM_FRAMES
	sub ebx, eax
	shl ebx, 24 + 2
	or r8d, ebx
	mov eax, [rdi].Fire.p1.x
	sar eax, 16
	mov [screen_point1].x, eax
	mov eax, [rdi].Fire.p1.y
	sar eax, 16
	mov [screen_point1].y, eax
	mov eax, [rdi].Fire.p2.x
	sar eax, 16
	mov [screen_point2].x, eax
	mov eax, [rdi].Fire.p2.y
	sar eax, 16
	mov [screen_point2].y, eax
	call screen_drawLine
endm

; in:
	; r8  - point1 (as qword ptr)
	; r10 - point2 (as qword ptr)
fire_create proc
	; look for empty spot
	lea rdi, fires
	mov ecx, MAX_NUM_FIRES
	mainLoop:
		cmp [rdi].Fire.is_alive, 0
		jne next

		inc [rdi].Fire.is_alive
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
			ja p1xGreater
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
			ja p1yGreater
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

