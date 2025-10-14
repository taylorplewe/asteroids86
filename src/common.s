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
		vmovdqa ymm0, ymmword ptr [rsi]
		vmovdqa ymmword ptr [rdi], ymm0
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
	shl eax, 2 ; 4-byte values

	lea rdx, sintab
	mov eax, dword ptr [rdx + rax]

	ret
sin endp

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


endif
