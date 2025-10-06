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

; cos:
; 	clc ; clear carry for add
; 	adc #$40 ; add 1/4 rotation

; ; get SIN(A:8) in A:16. enter with the Z flag reflecting the contents of A
; sin:
; 	bpl @sinCos		; just get SIN/COS and return if +ve

; 	and #$7f		; else make +ve
; 	jsr @sinCos		; get SIN/COS
	
; 	; now do twos complement
; 	a16
; 	neg
; 	a8
; 	rts

; 	; get 16-bit A from SIN/COS table
; 	@sinCos:
; 	cmp #$41		; compare with max+1
; 	bcc @quadrant	; branch if less

; 	eor #$7f		; wrap $41-$7f ..
; 	inc             ; .. to $3F-$00

; 	@quadrant:
; 	asl	a			; * 2 bytes per value
; 	i8
; 	a16
; 	tax				; copy to index
; 	lda sintab, x	; get 16-bit SIN/COS table value
; 	i16
; 	a8
; 	rts
