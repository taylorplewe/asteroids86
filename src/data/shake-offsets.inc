%ifndef shakeOffsets_h
%define shakeOffsets_h


.data

bounce_offsets:
	db 0 ; logic checks that the index is NOT zero, so starts on 1
	db 10
	db 15
	db 18
	db 20
	db 18
	db 15
	db 10
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
bounce_offset_len equ $ - bounce_offsets

shake_offsets_x:
	db 8
	db -10
	db 6


%endif
