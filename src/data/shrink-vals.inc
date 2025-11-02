ifndef shrinkVals_h
shrinkVals_h = 1


.data

shrink_vals:
	dd 00010000h
	dd 0000ff80h ; - 0080
	dd 0000fe80h ; - 0100
	dd 0000fc00h ; - 0300
	dd 0000f800h ; - 0800
	dd 0000ed00h ; - 0b00
	dd 0000e000h ; - 0d00
	dd 0000d000h ; - 1000
	dd 0000b800h ; - 1800
	dd 00009800h ; - 2000
	dd 00006800h ; - 3000
	dd 00002000h ; - 4800
shrink_vals_len = ($ - shrink_vals) / 4


endif
