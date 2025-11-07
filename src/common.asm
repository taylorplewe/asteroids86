%ifndef common_h
%define common_h

%include "src/globaldefs.inc"
%include "src/data/sintab.inc"


section .text

; in:
	; rdi = destination ptr
	; rsi = source ptr
	; ecx = count of qwords
memcpyAligned32:
	.mainLoop:
		vmovdqu ymm0, ymmword [rsi]
		vmovdqu ymmword [rdi], ymm0
		add rsi, 32
		add rdi, 32
		loop .mainLoop
	ret

	; loop duration (in clock cycles) moving 8 bytes at a time with RAX:
		; 7,340,032 cycles
	; loop duration (in clock cycles) moving 32 bytes at a time with YMM0 (SIMD):
		; 2,246,728 cycles


cos:
	add al, 40h


sin:
	cmp al, 80h
	jb .sinCos

	and al, 7fh
	call sinCos

	neg eax
	ret

	.sinCos:
	cmp al, 41h
	jb .quadrant

	xor al, 7fh
	inc al

	.quadrant:
	push rdx

	shl eax, 2 ; 4-byte values

	lea rdx, sintab
	mov eax, dword [rdx + rax]

	pop rdx
	ret


; This is a translation of a "FastAtan2" method from a disassembly of Legacy of Kain: Soul Reaver (https://github.com/FedericoMilesi/soul-re/blob/8d859e8a3885e8c57f51e42bdb299fa2180258cc/src/Game/MATH3D.c#L132)
; in:
	; ebx - y
	; ecx - x
; out:
	; al - angle in 256-based radians
atan2:
	push rdx
	push r8
	push r9

    ; if (x == 0) {
    ;     x = 1;
    ; }
	test ecx, ecx
	jne ._
		inc ecx
	._:

    ; if (y == 0) {
    ;     return (x < 1) * 128;
    ; }
    test ebx, ebx
	jne ._1
		xor eax, eax
		sub ecx, 1
		sar ecx, 24
		and ecx, 80h
		mov eax, ecx
		jmp .end
	._1:
	
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
	jl .xGreaterThanZeroEnd
	    ; if (y > 0)
		cmp ebx, 0
		jl .xGreaterThanZeroYGreaterThanZeroEnd
		    ; if (ax < ay)
			cmp r8d, r9d
			jge ._2
        		; return (64 - ((ax * 32) / ay));
				shl r8d, 5
				mov eax, r8d
				cdq
				div r9d
				mov ebx, 64
				sub ebx, eax
				mov eax, ebx
				jmp .end
			._2:
				; return ((ay * 32) / ax);
				shl r9d, 5
				mov eax, r9d
				cdq
				div r8d
				jmp .end
		.xGreaterThanZeroYGreaterThanZeroEnd:
		    ; if (ay < ax)
		    cmp r9d, r8d
			jge ._3
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
				jl .end
				dec eax
				jmp .end
			._3:
				; return (((ax * 32) / ay) + 196);
				shl r8d, 5
				mov eax, r8d
				cdq
				div r9d
				add eax, 196
				jmp .end
    .xGreaterThanZeroEnd:

    ; if (y > 0)
	cmp ebx, 0
	jl .yGreaterThanZeroEnd
		; if (ax < ay)
		cmp r8d, r9d
		jge ._4
			; return (((ax * 32) / ay) + 64);
			shl r8d, 5
			mov eax, r8d
			cdq
			div r9d
			add eax, 64
			jmp .end
		._4:
			; return (128 - ((ay * 32) / ax));
			shl r9d, 5
			mov eax, r9d
			cdq
			div r8d
			mov ebx, 128
			sub ebx, eax
			mov eax, ebx
			jmp .end
	.yGreaterThanZeroEnd:

    ; if (ay < ax)
    cmp r9d, r8d
	jge ._5
		; return (((ay * 32) / ax) + 128);
		shl r9d, 5
		mov eax, r9d
		cdq
		div r8d
		add eax, 128
		jmp .end
	._5:
		; return (196 - ((ax * 32) / ay));
		shl r8d, 5
		mov eax, r8d
		cdq
		div r9d
		mov ebx, 196
		sub ebx, eax
		mov eax, ebx
		; jmp .end

	.end:
	add al, 64
	pop r9
	pop r8
	pop rdx
	ret


; in:
	; r8   - pointer to source BasePoint
	; r9   - pointer to destination Point
	; r10  - pointer to origin point (16.16 fixed point)
	; r11b - rotation in 256-based radians
	; r12d - factor to multiply vector by (16.16 fixed point)
applyBasePointToPoint:
	push rbx
	push rcx

	xor rax, rax
	mov al, byte [r8 + BasePoint.rad]
	add al, r11b
	mov bl, al
	; x
	mov al, bl
	call sin
	mov ecx, dword [r8 + BasePoint.vec]
	cdqe
	imul rax, rcx
	sar rax, 31
	imul rax, r12
	sar rax, 16
	mov ecx, eax
	mov eax, dword [r10 + Point.x]
	shr eax, 16
	add eax, ecx
	mov dword [r9 + Point.x], eax
	; y
	xor eax, eax ; clear upper bits
	mov al, bl
	call cos
	mov ecx, dword [r8 + BasePoint.vec]
	cdqe
	imul rax, rcx
	sar rax, 31
	imul rax, r12
	sar rax, 16
	mov ecx, eax
	mov eax, dword [r10 + Point.y]
	shr eax, 16
	sub eax, ecx
	mov dword [r9 + Point.y], eax

	pop rcx
	pop rbx
	ret


; in:
	; rsi - pointer to 16.16 fixed-point point
wrapPointAroundScreen:
	cmp dword [rsi + Point.x], 0
	jg ._1
	add dword [rsi + Point.x], SCREEN_WIDTH << 16
	._1:
	cmp dword [rsi + Point.x], SCREEN_WIDTH << 16
	jb ._2
	sub dword [rsi + Point.x], SCREEN_WIDTH << 16
	._2:
	cmp [rsi + Point.y], 0
	jg ._3
	add dword [rsi + Point.y], SCREEN_HEIGHT << 16
	._3:
	cmp dword [rsi + Point.y], SCREEN_HEIGHT << 16
	jb ._4
	sub dword [rsi + Point.y], SCREEN_HEIGHT << 16
	._4:
	ret


; Get a 16.16 fixed point X and Y velocity (together in one 64-bit register) from an 8-bit rotation value and a speed scaling vector
; in:
	; r10b - rotation in 256-based radians
	; ecx  - speed vector
; out:
	; rax  - (velocity.y << 32) | (velocity.x) (16.16 fixed point each)
getVelocityFromRotAndSpeed:
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


; out:
	; rax - Y in upper 32 bits, X in lower; both 16.16 fixed point
getRandomOnscreenFixedPointPos:
	push rbx
	push rdx
	push r8
	
	; random on-screen pos
	; x
	mov r8w, SCREEN_WIDTH
	xor eax, eax
	rand ax
	and ax, 7fffh
	cwd
	div r8w
	mov ebx, edx
	; y
	mov r8w, SCREEN_HEIGHT
	xor eax, eax
	rand ax
	and ax, 7fffh
	cwd
	div r8w
	shl rdx, 32
	or rbx, rdx
	shl rbx, 16

	mov rax, rbx
	pop r8
	pop rdx
	pop rbx
	ret



%endif
