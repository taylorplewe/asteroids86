ifndef shakeOffsets_h
shakeOffsets_h = 1


.data

bounce_offsets:
	db 0 ; logic checks that the index is NOT zero, so starts on 1
	db 10
	db 15
	db 20
	db 21
	db 22
	db 23
	db 22
	db 21
	db 20
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
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0
	db 0 ; NOTE: probs could get rid of some of these. Just want to let the other digits catch up
bounce_offset_len = $ - bounce_offsets

shake_offsets_x:
	db 8
	db -10
	db 6


endif
