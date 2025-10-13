Array struct
    data    FatPtr <?>
    cap     dd     ?
    el_size dq     ?
Array ends


.code

; in:
	; rsi - pointer to Array
; out:
    ; rax - pointer to new element if successful, 0 otherwise
array_push proc
	mov eax, [rsi].Array.data.len
	cmp eax, [rsi].Array.cap
	jge atCapacity

	push rsi

	inc [rsi].Array.data.len
    imul rax, [rsi].Array.el_size
    mov rsi, [rsi].Array.data.pntr
	add rax, rsi

	pop rsi
	ret

	atCapacity:
    xor eax, eax
	ret
array_push endp

; in:
	; rsi - pointer to array
	; eax - index to delete
array_removeAt proc
	push rdi
	push rcx

	dec [rsi].Array.data.len
	je _end

	mov rcx, [rsi].Array.el_size
	imul eax, ecx
	mov rdi, [rsi].Array.data.pntr
	add rdi, rax

	mov eax, [rsi].Array.data.len
	imul eax, ecx
	mov rsi, [rsi].Array.data.pntr
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
	pop rdi
	ret
array_removeAt endp

; in:
	; rsi - pointer to Array
	; r8  - pointer to callback routine
	;       (will pass rdi as the pointer to the element)
	;       (should return eax=1 if element was deleted during the callback, 0 otherwise)
array_forEach proc
	cmp [rsi].Array.data.len, 0
	je _end
	mov rdi, [rsi].Array.data.pntr
	xor ecx, ecx
	_loop:
		call r8
		test eax, eax
		jne nextCmp
		
		add rdi, [rsi].Array.el_size
		inc ecx
		nextCmp:
		cmp ecx, [rsi].Array.data.len
		jl _loop

	_end:
	ret
array_forEach endp

