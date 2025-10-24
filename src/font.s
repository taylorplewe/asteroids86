ifndef font_h
font_h = 1

include <windows\defs.inc>

include <global.s>


.data

font_digits_resource_name db    "FONTDIGITS", 0
font_test_pos             Point { 64 shl 16, 64 shl 16}
font_test_rect            Rect  { { 0, 0 }, { 32, 50 } }


.data?

font_digits_spr_data dq ?


.code

font_init proc
	xor rcx, rcx
	lea rdx, font_digits_resource_name
	lea r8, bin_resource_type
	call FindResourceA
	xor rcx, rcx
	mov rdx, rax
	call LoadResource
	mov rcx, rax
	call LockResource
	mov [font_digits_spr_data], rax

	ret
font_init endp

font_draw proc
	push rdx
	push rsi
	push r8
	push r9

	; rdx - pointer to onscreen Point to draw sprite (16.16 fixed point)
	; rsi - pointer to beginning of sprite data
	; r8d - color
	; r9  - pointer to in-spritesheet Rect, dimensions of sprite

	lea rdx, font_test_pos
	mov rsi, [font_digits_spr_data]
	mov r8d, [fg_color]
	lea r9, font_test_rect
	lea r14, scren_draw3difiedPixelOnscreenVerified

	call screen_draw1bppSprite

	xor eax, eax
	pop r9
	pop r8
	pop rsi
	pop rdx
	ret
font_draw endp


endif
