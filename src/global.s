ifndef global_h
global_h = 1


.data

zero64        db    64 dup (0)
fg_color      Pixel <0ffh, 0ffh, 0ffh, 0ffh>
evil_color    Pixel <0ffh, 0a0h, 080h, 0ffh>


.data?

frame_counter qword ?


endif
