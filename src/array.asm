%ifndef array_h
%define array_h


struc Array
    .data:    resb FatPtr_size
    .cap:     resd 1
    .el_size: resq 1
endstruc


section .text

; in:
	; rsi - pointer to Array
; out:
    ; rax - pointer to new element if successful, 0 otherwise
array_push:
	mov eax, [rsi + Array.data.len]
	cmp eax, [rsi + Array.cap]
	jge .atCapacity

	inc [rsi + Array.data.len]
    imul rax, [rsi + Array.el_size]
    mov rsi, [rsi + Array.data.pntr]
	add rax, rsi

	ret

	.atCapacity:
    xor eax, eax
	ret


; in:
	; rsi - pointer to Array
	; eax - index to delete
array_removeAt:
	push rcx
	push rdi

	mov rcx, [rsi + Array.el_size]
	imul eax, ecx
	mov rdi, [rsi + Array.data.pntr]
	add rdi, rax

	call array_removeEl
	
	pop rdi
	pop rcx
	ret


; Takes the last element in an Array and copies it to a certain slot inside the Array; presumably where an element was just deleted.
; in:
	; rsi - point to Array
	; rdi - point to destination element slot in Array's memory
array_removeEl:
	push rcx
	push rsi
	push rdi

	dec [rsi + Array.data.len]
	je .end

	mov rcx, [rsi + Array.el_size]
	mov eax, [rsi + Array.data.len]
	imul eax, ecx
	mov rsi, [rsi + Array.data.pntr]
	add rsi, rax

	xor eax, eax
	.copyLoop:
		mov al, [rsi]
		mov [rdi], al
		inc rsi
		inc rdi
		loop copyLoop

	.end:
	pop rdi
	pop rsi
	pop rcx
	ret


; in:
	; rsi - pointer to Array
	; r8  - pointer to callback routine
	;       (will pass rdi as the pointer to the element)
	;       (should return eax=1 if element was deleted during the callback, 0 otherwise)
	;       (should return eax=-1 for break)
array_forEach:
	push rcx
	push rdi

	cmp [rsi + Array.data.len], 0
	je .end
	mov rdi, [rsi + Array.data.pntr]
	xor ecx, ecx
	.loop:
		call r8
		test eax, eax
		cmp eax, 1
		je .nextCmp
		cmp eax, -1
		je .end
		
		add rdi, [rsi + Array.el_size]
		inc ecx
		.nextCmp:
		cmp ecx, [rsi + Array.data.len]
		jl .loop

	.end:
	pop rdi
	pop rcx
	ret


; in:
	; rsi - pointer to Array
array_clear:
	mov [rsi + Array.data.len], 0
	; mov ecx, [rsi + Array.cap]
	; imul rcx, [rsi + Array.el_size]
	; mov rsi, [rsi + Array.data.pntr]
	; .loop:
	; 	mov byte [rsi], 0
	; 	inc rsi
	; 	loop .loop
	ret



%endif
