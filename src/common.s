.code

cos proc
	add al, 40h
cos endp

sin proc
	cmp al, 80h
	jb sinCos

	and al, 7fh
	call sinCos

	neg eax
	ret

	sinCos:
	cmp al, 41h
	jb quadrant

	xor al, 7fh
	inc al

	quadrant:
	shl eax, 2 ; 4-byte values

	lea rdx, sintab
	mov eax, dword ptr [rdx + rax]

	ret
sin endp
