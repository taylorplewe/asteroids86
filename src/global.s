ifndef global_h
global_h = 1


.data

zero64        db    64 dup (0)
fg_color      Pixel <0ffh, 0ffh, 0ffh, 0ffh>
dim_color     Pixel <0ffh, 0ffh, 0ffh, 030h>
evil_color    Pixel <0ffh, 0a0h, 080h, 0ffh>


.data?

frame_counter qword ?
flash_color   Pixel <>


endif
