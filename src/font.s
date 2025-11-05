%ifndef font_h
%define font_h

%include "src/global.s"


FONT_SM_CHAR_WIDTH    equ 16
FONT_SM_CHAR_HEIGHT   equ 25
FONT_LG_CHAR_WIDTH    equ 40
FONT_LG_CHAR_HEIGHT   equ 51
FONT_DIGIT_WIDTH      equ 32
FONT_DIGIT_HEIGHT     equ 50
FONT_DIGIT_KERNING    equ FONT_DIGIT_WIDTH + 8
FONT_SM_W_WIDTH       equ 32
FONT_SM_W_HEIGHT      equ FONT_SM_CHAR_HEIGHT
FONT_COPYRIGHT_WIDTH  equ 16
FONT_COPYRIGHT_HEIGHT equ FONT_COPYRIGHT_WIDTH

FONT_LG_X_S equ FONT_LG_CHAR_WIDTH * 0
FONT_LG_X_T equ FONT_LG_CHAR_WIDTH * 1
FONT_LG_X_A equ FONT_LG_CHAR_WIDTH * 2
FONT_LG_X_R equ FONT_LG_CHAR_WIDTH * 3
FONT_LG_X_G equ FONT_LG_CHAR_WIDTH * 4
FONT_LG_X_M equ FONT_LG_CHAR_WIDTH * 5
FONT_LG_X_E equ FONT_LG_CHAR_WIDTH * 6
FONT_LG_X_O equ FONT_LG_CHAR_WIDTH * 7
FONT_LG_X_V equ FONT_LG_CHAR_WIDTH * 8

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

font_digits_resource_name    db   "FONTDIGITS", 0
font_yr_digits_resource_name db   "FONTYRDIGITS", 0
font_large_resource_name     db   "FONTBIG", 0
font_small_resource_name     db   "FONTSMALL", 0
font_small_w_resource_name   db   "FONTSMALLW", 0
font_comma_resource_name     db   "COMMA", 0
font_copyright_resource_name db   "COPYRIGHT", 0
font_char_rect               Rect { { 0, 0 }, { FONT_DIGIT_WIDTH, FONT_DIGIT_HEIGHT } }
font_comma_rect              Rect { { 0, 0 }, { 8, 15 } }


.data?

font_digits_spr_data    dq    ?
font_yr_digits_spr_data dq    ?
font_large_spr_data     dq    ?
font_small_spr_data     dq    ?
font_small_w_spr_data   dq    ?
font_comma_spr_data     dq    ?
font_copyright_spr_data dq    ?
font_current_char_pos   Point <>
font_current_char_rect  Rect  <>


.code

font_initSprData proc
	font_loadSprData font_digits_resource_name, font_digits_spr_data
	font_loadSprData font_yr_digits_resource_name, font_yr_digits_spr_data
	font_loadSprData font_large_resource_name, font_large_spr_data
	font_loadSprData font_small_resource_name, font_small_spr_data
	font_loadSprData font_small_w_resource_name, font_small_w_spr_data
	font_loadSprData font_comma_resource_name, font_comma_spr_data
	font_loadSprData font_copyright_resource_name, font_copyright_spr_data

	ret
font_initSprData endp


%endif
