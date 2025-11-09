%ifndef font_h
%define font_h

%include "src/global.asm"



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

%macro font_loadSprData 2 ;resource_name:req, dest_spr_data:req
	xor rcx, rcx
	lea rdx, %1
	lea r8, bin_resource_type
	call FindResourceA
	xor rcx, rcx
	mov rdx, rax
	call LoadResource
	mov rcx, rax
	call LockResource
	mov [%2], rax
%endmacro


section .data

font_digits_resource_name    db   "FONTDIGITS", 0
font_yr_digits_resource_name db   "FONTYRDIGITS", 0
font_large_resource_name     db   "FONTBIG", 0
font_small_resource_name     db   "FONTSMALL", 0
font_small_w_resource_name   db   "FONTSMALLW", 0
font_comma_resource_name     db   "COMMA", 0
font_copyright_resource_name db   "COPYRIGHT", 0
font_char_rect:
	istruc Rect
		istruc Point
			at .x,    dd 0
			at .y,    dd 0
		iend
		istruc Point
			at .x,    dd FONT_DIGIT_WIDTH
			at .y,    dd FONT_DIGIT_HEIGHT
		iend
	iend
font_comma_rect:
	istruc Rect
		istruc Point
			at .x,    dd 0
			at .y,    dd 0
		iend
		istruc Point
			at .x,    dd 8
			at .y,    dd 15
		iend
	iend

font_digits_spr_data:    incbin "resources/font-digits.bin"
font_yr_digits_spr_data: incbin "resources/font-year-digits.bin"
font_large_spr_data:     incbin "resources/font-big.bin"
font_small_spr_data:     incbin "resources/font-small.bin"
font_small_w_spr_data:   incbin "resources/font-small-w.bin"
font_comma_spr_data:     incbin "resources/comma.bin"
font_copyright_spr_data: incbin "resources/copyright.bin"


section .bss

; font_digits_spr_data    resq    1
; font_yr_digits_spr_data resq    1
; font_large_spr_data     resq    1
; font_small_spr_data     resq    1
; font_small_w_spr_data   resq    1
; font_comma_spr_data     resq    1
; font_copyright_spr_data resq    1
font_current_char_pos   resb Point_size
font_current_char_rect  resb Rect_size


%endif
