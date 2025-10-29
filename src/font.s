ifndef font_h
font_h = 1

include <windows\defs.inc>

include <global.s>


FONT_SM_CHAR_WIDTH  = 16
FONT_SM_CHAR_HEIGHT = 25
FONT_LG_CHAR_WIDTH  = 40
FONT_LG_CHAR_HEIGHT = 51
FONT_DIGIT_WIDTH    = 32
FONT_DIGIT_HEIGHT   = 50
FONT_DIGIT_KERNING  = FONT_DIGIT_WIDTH + 8

font_loadSprData macro resource_name:req, dest_spr_data:req
	xor rcx, rcx
	lea rdx, resource_name
	lea r8, bin_resource_type
	call FindResourceA
	xor rcx, rcx
	mov rdx, rax
	call LoadResource
	mov rcx, rax
	call LockResource
	mov [dest_spr_data], rax
endm


.data

font_digits_resource_name db    "FONTDIGITS", 0
font_comma_resource_name  db    "COMMA", 0
font_char_rect            Rect  { { 0, 0 }, { FONT_DIGIT_WIDTH, FONT_DIGIT_HEIGHT } }
font_comma_rect           Rect  { { 0, 0 }, { 8, 15 } }


.data?

font_digits_spr_data dq ?
font_comma_spr_data  dq ?


.code

font_init proc
	font_loadSprData font_digits_resource_name, font_digits_spr_data
	font_loadSprData font_comma_resource_name, font_comma_spr_data

	ret
font_init endp


endif
