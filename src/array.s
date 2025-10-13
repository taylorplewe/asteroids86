Array struct
    data    FatPtr <?>
    cap     dd     ?
    el_size dd     ?
Array ends

; in:
	; rdi - pointer to Array
; out:
    ; rax - pointer to new element if successful, 0 otherwise
array_push proc
	mov eax, [rdi].Array.data.len
	cmp eax, [rdi].Array.cap
	jge atCapacity

	inc [rdi].Array.data.len
    imul eax, [rdi].Array.el_size
    mov rdi, [rdi].Array.data.pntr
    add rdi, rax
    mov rax, rdi
	ret

	atCapacity:
    xor eax, eax
	ret
array_push endp

; in:
	; rdi - pointer to array
	; eax - index to delete
array_remove proc
	push rsi
	push rcx

	dec [rdi].Array.data.len
	je _end

	mov ecx, [rdi].Array.el_size
	imul eax, ecx
	mov rdi, [rdi].Array.data.pntr
	add rdi, rax

	mov eax, [rdi].Array.data.len
	imul eax, ecx
	mov rsi, [rdi].Array.data.pntr
	add rsi, rax

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
array_remove endp

