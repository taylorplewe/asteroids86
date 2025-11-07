%ifndef global_h
%define global_h


GAMEOVER_TIMER_AMT equ 60 * 4


section .data

zero64:            db    64 dup (0)
fg_color:
    istruc Pixel
        at .r, db 0ffh
        at .g, db 0ffh
        at .b, db 0ffh
        at .a, db 0ffh
    iend
gray_color:
    istruc Pixel
        at .r, db 050h
        at .g, db 050h
        at .b, db 050h
        at .a, db 0ffh
    iend
dim_color:
    istruc Pixel
        at .r, db 0ffh
        at .g, db 0ffh
        at .b, db 0ffh
        at .a, db 030h
    iend
evil_color:
    istruc Pixel
        at .r, db 0ffh
        at .g, db 0a0h
        at .b, db 080h
        at .a, db 0ffh
    iend
bin_resource_type: db    "BIN", 0


section .bss

frame_counter:       resq 1
mode:                resd 1
event_bus:           resd 1
flash_color:         resb Pixel_size
num_flashes_left:    resd 1
score:               resd 1
lives:               resd 1
gameover_timer:      resd 1
gameover_visibility: resd 1
is_in_gameover:      resd 1


%endif
