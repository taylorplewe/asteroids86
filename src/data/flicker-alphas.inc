ifndef flickerAlphas_h
flickerAlphas_h = 1

include <globaldefs.inc>


FLICKER_100 = 0ffh
FLICKER_90  = (((0ffh - DIM_ALPHA) / 10) * 9) + DIM_ALPHA
FLICKER_80  = (((0ffh - DIM_ALPHA) / 10) * 8) + DIM_ALPHA
FLICKER_70  = (((0ffh - DIM_ALPHA) / 10) * 7) + DIM_ALPHA
FLICKER_60  = (((0ffh - DIM_ALPHA) / 10) * 6) + DIM_ALPHA
FLICKER_50  = (((0ffh - DIM_ALPHA) / 10) * 5) + DIM_ALPHA
FLICKER_40  = (((0ffh - DIM_ALPHA) / 10) * 4) + DIM_ALPHA
FLICKER_30  = (((0ffh - DIM_ALPHA) / 10) * 3) + DIM_ALPHA
FLICKER_20  = (((0ffh - DIM_ALPHA) / 10) * 2) + DIM_ALPHA
FLICKER_10  = (((0ffh - DIM_ALPHA) / 10) * 1) + DIM_ALPHA
FLICKER_0   = DIM_ALPHA



.data

flicker_alphas:
	db FLICKER_0
	db FLICKER_100
	db FLICKER_100
	db FLICKER_90
	db FLICKER_20
	db FLICKER_70
	db FLICKER_90
	db FLICKER_80
	db FLICKER_90
	db FLICKER_20
	db FLICKER_60
	db FLICKER_60
	db FLICKER_50
	db FLICKER_40
	db FLICKER_50
	db FLICKER_50
	db FLICKER_30
	db FLICKER_0
	db FLICKER_40
	db FLICKER_0
	db FLICKER_20
flicker_alphas_end = $


endif
