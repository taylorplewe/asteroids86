ifndef font_h
font_h = 1

include <windows\defs.inc>

include <global.s>


FONT_DIGIT_WIDTH  = 32
FONT_DIGIT_HEIGHT = 50
FONT_KERNING      = 8


.data

font_digits_resource_name db    "FONTDIGITS", 0
font_char_rect            Rect  { { 0, 0 }, { FONT_DIGIT_WIDTH, FONT_DIGIT_HEIGHT } }


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


endif
