ifndef global_h
global_h = 1


GAMEOVER_TIMER_AMT = 60 * 4


.data

zero64            db    64 dup (0)
fg_color          Pixel <0ffh, 0ffh, 0ffh, 0ffh>
gray_color        Pixel <050h, 050h, 050h, 0ffh>
dim_color         Pixel <0ffh, 0ffh, 0ffh, 030h>
evil_color        Pixel <0ffh, 0a0h, 080h, 0ffh>
bin_resource_type db    "BIN", 0


.data?

frame_counter       qword ?
flash_color         Pixel <>
num_flashes_left    dd ?
score               dd ?
lives               dd ?
gameover_timer      dd ?
gameover_visibility dd ?
is_in_gameover      dd ?


endif
