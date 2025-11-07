%ifndef fire_h
%define fire_h

%include "src/screen.asm"
%include "src/array.asm"


struc Fire
	.num_frames_alive: resd     1
	.p1:               resb Point_size ; 16.16 fixed point
	.p2:               resb Point_size ; 16.16 fixed point
    .shrink_vec:       resb Vector_size ; p1 will ADD this value to get towards the center, p2 will SUBTRACT
	.rot:              resb     1
endstruc
FIRE_VELOCITY       equ 1
FIRE_MAX_NUM_FRAMES equ 30
MAX_NUM_FIRES       equ 64


section .data

fires_arr:
	istruc Array
		istruc FatPtr
			at .pntr, dq fires
			at .len, dd 0
		iend
		at .cap, dd MAX_NUM_FIRES
		at .el_size, dd Fire_size
	iend
fire_color:
	istruc Pixel
		at .r, db 0ffh
		at .g, db 0
		at .b, db 0
		at .a, db 0ffh
	iend


section .bss

fires: resb Fire_size * MAX_NUM_FIRES


section .text

; in:
	; r8  - point1 (as qword ptr)
	; r10 - point2 (as qword ptr)
	; bl  - rotation in 256-based radians
fire_create:
	push rsi
	push r9
	push r11
	push r13

	lea rsi, fires_arr
	call array_push
	test eax, eax
	je .end

	mov rsi, rax

	mov [rsi + Fire.rot], bl
	mov [rsi + Fire.num_frames_alive], 0
	mov qword [rsi + Fire.p1], r8
	mov qword [rsi + Fire.p2], r10

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
		jg .p1xGreater
		.p2xGreater:
			mov eax, r10d
			mov ebx, r8d
			jmp .xCenterFinish
		.p1xGreater:
			mov eax, r8d
			mov ebx, r10d
		.xCenterFinish:
		sub eax, ebx
		shr eax, 1 ; /2
		add ebx, eax
		mov r12d, ebx
	; y
		cmp r9d, r11d
		jg .p1yGreater
		.p2yGreater:
			mov eax, r11d
			mov ebx, r9d
			jmp .yCenterFinish
		.p1yGreater:
			mov eax, r9d
			mov ebx, r11d
		.yCenterFinish:
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
		mov [rsi + Fire.shrink_vec.x], eax
	; y
		mov eax, r13d
		sub eax, r9d
		mov ebx, FIRE_MAX_NUM_FRAMES
		cdq
		idiv ebx
		mov [rsi + Fire.shrink_vec.y], eax

	.end:
	pop r13
	pop r11
	pop r9
	pop rsi

	ret


fire_updateAll:
	lea rsi, fires_arr
	lea r8, fire_update
	jmp array_forEach


; in:
	; rdi - pointer to fire
; out:
	; eax - 1 if fire was destroyed
fire_update:
	push rcx
	push rsi

	inc [rdi + Fire.num_frames_alive]
	cmp [rdi + Fire.num_frames_alive], FIRE_MAX_NUM_FRAMES
	jl ._
		; destroy fire
		lea rsi, fires_arr
		call array_removeEl
		mov eax, 1
		jmp .end
	._:

	; move fire
	; x
	xor rax, rax
	mov al, [rdi + Fire.rot]
	call sin
	cdqe
	imul rax, FIRE_VELOCITY
	sar rax, 15
	add [rdi + Fire.p1.x], eax
	add [rdi + Fire.p2.x], eax
	; y
	xor rax, rax
	mov al, [rdi + Fire.rot]
	call cos
	cdqe
	imul rax, FIRE_VELOCITY
	sar rax, 15
	neg eax
	add [rdi + Fire.p1.y], eax
	add [rdi + Fire.p2.y], eax

	; shrink fire
	mov eax, [rdi + Fire.shrink_vec.x]
	add [rdi + Fire.p1.x], eax
	sub [rdi + Fire.p2.x], eax
	mov eax, [rdi + Fire.shrink_vec.y]
	add [rdi + Fire.p1.y], eax
	sub [rdi + Fire.p2.y], eax

	mov eax, 0

	.end:
	pop rsi
	pop rcx
	ret


fire_drawAll:
	lea rsi, fires_arr
	lea r8, fire_draw
	jmp array_forEach


; in:
	; rdi - pointer to fire
; out:
	; eax - 0 (fire wasn't destroyed)
fire_draw:
	push rbx
	push rcx
	push rdx
	push rdi
	push r8
	push r9
	push r10

	; color
	mov r8d, [fire_color]
	and r8d, 000000ffh
	mov eax, [rdi + Fire.num_frames_alive]
	mov ebx, FIRE_MAX_NUM_FRAMES
	mov ecx, ebx
	mov r9d, ebx
	mov edx, eax
	mov r10d, eax

	; alpha
	sub ebx, eax
	add ebx, 15
	shl ebx, 24 + 2
	or r8d, ebx

	; green
	shl edx, 1
	cmp edx, ecx
	jg ._
	sub ecx, edx
	add ecx, 15
	shl ecx, 8 + 2
	or r8d, ecx
	._:

	; blue
	shl r10d, 2
	cmp r10d, r9d
	jg ._1
	sub r9d, r10d
	add r9d, 15
	shl r9d, 16 + 2
	or r8d, r9d
	._1:

	xor eax, eax ; clear upper bits
	mov ax, word [rdi + Fire.p1.x + 2]
	cwde
	mov [screen_point1 + Point.x], eax
	mov ax, word [rdi + Fire.p1.y + 2]
	cwde + Point
	mov [screen_point1 + Point.y], eax
	mov ax, word [rdi + Fire.p2.x + 2]
	cwde
	mov [screen_point2 + Point.x], eax
	mov ax, word [rdi + Fire.p2.y + 2]
	cwde
	mov [screen_point2 + Point.y], eax

	call screen_drawLine

	xor eax, eax ; fire not destroyed
	pop r10
	pop r9
	pop r8
	pop rdi
	pop rdx
	pop rcx
	pop rbx
	ret



%endif
