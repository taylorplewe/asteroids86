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

; in:
	; ebx - y
	; ecx - x
atan2 proc
	ret
atan2 endp

	; atan2(long y, long x):

    ; long ax;
    ; long ay;

    ; if (x == 0) {
    ;     x = 1;
    ; }

    ; if (y == 0) {
    ;     return (x < 1) * 2048;
    ; }

    ; ax = abs(x);
    ; ay = abs(y);

    ; if (x > 0) {
    ;     if (y > 0)
    ;     {
    ;         if (ax < ay)
    ;         {
    ;             return (1024 - ((ax * 512) / ay));
    ;         }
    ;         else
    ;         {
    ;             return ((ay * 512) / ax);
    ;         }
    ;     }
    ;     else
    ;     {
    ;         if (ay < ax)
    ;         {
    ;             return (4096 - ((ay * 512) / ax));
    ;         }
    ;         else
    ;         {
    ;             return (((ax * 512) / ay) + 3072);
    ;         }
    ;     }
    ; }

    ; if (y > 0) {
    ;     if (ax < ay)
    ;     {
    ;         return (((ax * 512) / ay) + 1024);
    ;     }
    ;     else
    ;     {
    ;         return (2048 - ((ay * 512) / ax));
    ;     }
    ; }

    ; if (ay < ax) {
    ;     return (((ay * 512) / ax) + 2048);
    ; }
    ; else {
    ;     return (3072 - ((ax * 512) / ay));
    ; }

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
