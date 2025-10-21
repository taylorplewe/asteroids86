ifndef common_h
common_h = 1

include <globaldefs.inc>
include <data\sintab.inc>


.code

; in:
	; rdi = destination ptr
	; rsi = source ptr
	; ecx = count of qwords
memcpyAligned32 proc
	mainLoop:
		vmovdqu ymm0, ymmword ptr [rsi]
		vmovdqu ymmword ptr [rdi], ymm0
		add rsi, 32
		add rdi, 32
		loop mainLoop
	ret

	; loop duration (in clock cycles) moving 8 bytes at a time with RAX:
		; 7,340,032 cycles
	; loop duration (in clock cycles) moving 32 bytes at a time with YMM0 (SIMD):
		; 2,246,728 cycles
memcpyAligned32 endp

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
	push rdx

	shl eax, 2 ; 4-byte values

	lea rdx, sintab
	mov eax, dword ptr [rdx + rax]

	pop rdx
	ret
sin endp

; This is a translation of a "FastAtan2" method from a disassembly of Legacy of Kain: Soul Reaver (https://github.com/FedericoMilesi/soul-re/blob/8d859e8a3885e8c57f51e42bdb299fa2180258cc/src/Game/MATH3D.c#L132)
; in:
	; ebx - y
	; ecx - x
; out:
	; al - angle in 256-based radians
atan2 proc
	push rdx
	push r8
	push r9

    ; if (x == 0) {
    ;     x = 1;
    ; }
	test ecx, ecx
	jne @f
		inc ecx
	@@:

    ; if (y == 0) {
    ;     return (x < 1) * 128;
    ; }
    test ebx, ebx
	jne @f
		xor eax, eax
		sub ecx, 1
		sar ecx, 24
		and ecx, 80h
		mov eax, ecx
		jmp _end
	@@:
	
    ; ax = abs(x);
    ; ay = abs(y);
	mov eax, ecx
	abseax
	mov r8d, eax
	mov eax, ebx
	abseax
	mov r9d, eax

    ; if (x > 0)
	cmp ecx, 0
	jl xGreaterThanZeroEnd
	    ; if (y > 0)
		cmp ebx, 0
		jl xGreaterThanZeroYGreaterThanZeroEnd
		    ; if (ax < ay)
			cmp r8d, r9d
			jge @f
        		; return (64 - ((ax * 32) / ay));
				shl r8d, 5
				mov eax, r8d
				cdq
				div r9d
				mov ebx, 64
				sub ebx, eax
				mov eax, ebx
				jmp _end
			@@:
				; return ((ay * 32) / ax);
				shl r9d, 5
				mov eax, r9d
				cdq
				div r8d
				jmp _end
		xGreaterThanZeroYGreaterThanZeroEnd:
		    ; if (ay < ax)
		    cmp r9d, r8d
			jge @f
				; return (256 - ((ay * 32) / ax));
				shl r9d, 5
				mov eax, r9d
				cdq
				div r8d
				mov ebx, 256
				sub ebx, eax
				mov eax, ebx
				; could be 256 (al would be 0 which is very wrong)
				cmp eax, 256
				jl _end
				dec eax
				jmp _end
			@@:
				; return (((ax * 32) / ay) + 196);
				shl r8d, 5
				mov eax, r8d
				cdq
				div r9d
				add eax, 196
				jmp _end
    xGreaterThanZeroEnd:

    ; if (y > 0)
	cmp ebx, 0
	jl yGreaterThanZeroEnd
		; if (ax < ay)
		cmp r8d, r9d
		jge @f
			; return (((ax * 32) / ay) + 64);
			shl r8d, 5
			mov eax, r8d
			cdq
			div r9d
			add eax, 64
			jmp _end
		@@:
			; return (128 - ((ay * 32) / ax));
			shl r9d, 5
			mov eax, r9d
			cdq
			div r8d
			mov ebx, 128
			sub ebx, eax
			mov eax, ebx
			jmp _end
	yGreaterThanZeroEnd:

    ; if (ay < ax)
    cmp r9d, r8d
	jge @f
		; return (((ay * 32) / ax) + 128);
		shl r9d, 5
		mov eax, r9d
		cdq
		div r8d
		add eax, 128
		jmp _end
	@@:
		; return (196 - ((ax * 32) / ay));
		shl r8d, 5
		mov eax, r8d
		cdq
		div r9d
		mov ebx, 196
		sub ebx, eax
		mov eax, ebx
		; jmp _end

	_end:
	add al, 64
	pop r9
	pop r8
	pop rdx
	ret
atan2 endp

; in:
	; r8   - pointer to source BasePoint
	; r9   - pointer to destination Point
	; r10  - pointer to origin point
	; r11b - rotation in 256-based radians
	; r12d - factor to multiply vector by (16.16 fixed point)
applyBasePointToPoint proc
	xor rax, rax
	mov al, [r8].BasePoint.rad
	add al, r11b
	mov bl, al
	; x
	mov al, bl
	call sin
	mov ecx, [r8].BasePoint.vec
	cdqe
	imul rax, rcx
	sar rax, 31
	imul rax, r12
	sar rax, 16
	mov ecx, eax
	mov eax, [r10].Point.x
	shr eax, 16
	add eax, ecx
	mov [r9].Point.x, eax
	; y
	xor eax, eax ; clear upper bits
	mov al, bl
	call cos
	mov ecx, [r8].BasePoint.vec
	cdqe
	imul rax, rcx
	sar rax, 31
	imul rax, r12
	sar rax, 16
	mov ecx, eax
	mov eax, [r10].Point.y
	shr eax, 16
	sub eax, ecx
	mov [r9].Point.y, eax

	ret
applyBasePointToPoint endp

; in:
	; rsi - pointer to 16.16 fixed-point point
wrapPointAroundScreen proc
	cmp [rsi].Point.x, 0
	jg @f
	add [rsi].Point.x, SCREEN_WIDTH shl 16
	@@:
	cmp [rsi].Point.x, SCREEN_WIDTH shl 16
	jb @f
	sub [rsi].Point.x, SCREEN_WIDTH shl 16
	@@:
	cmp [rsi].Point.y, 0
	jg @f
	add [rsi].Point.y, SCREEN_HEIGHT shl 16
	@@:
	cmp [rsi].Point.y, SCREEN_HEIGHT shl 16
	jb @f
	sub [rsi].Point.y, SCREEN_HEIGHT shl 16
	@@:
	ret
wrapPointAroundScreen endp

; Get a 16.16 fixed point X and Y velocity (together in one 64-bit register) from an 8-bit rotation value and a speed scaling vector
; in:
	; r10b - rotation in 256-based radians
	; ecx  - speed vector
; out:
	; rax  - (velocity.y << 32) | (velocity.x) (16.16 fixed point each)
getVelocityFromRotAndSpeed proc
	push rdx

	; x
	xor eax, eax
	mov al, r10b
	call sin
	cdqe
	imul rax, rcx
	sar rax, 15
	mov edx, eax

	; y
	xor eax, eax
	mov al, r10b
	call cos
	cdqe
	imul rax, rcx
	sar rax, 15

	shl rax, 32
	or rax, rdx

	pop rdx
	ret
getVelocityFromRotAndSpeed endp


endif
