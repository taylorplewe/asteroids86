ifndef global_h
global_h = 1


.data

zero64        db    64 dup (0)
frame_counter qword ?
fg_color      Pixel <0ffh, 0ffh, 0ffh, 0ffh>


endif
