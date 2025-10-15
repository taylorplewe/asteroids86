ifndef ufo_h
ufo_h = 1

include <globaldefs.inc>

include <array.s>
include <screen.s>


Ufo struct
	pos         Point <?>
	targ_pos    Point <?>
	shoot_timer dd    ?
	; turn_timer  dd    ?
Ufo ends

MAX_NUM_UFOS = 4


.data

ufos     Ufo   MAX_NUM_UFOS dup (<>)
ufos_arr Array { { ufos, 0 }, MAX_NUM_UFOS, sizeof Ufo }


.code

; in:
	; rbx - pos
ufo_create proc
	lea rsi, ufos_arr
	call array_push
ufo_create endp

ufo_updateAll proc
	lea rsi, ufos_arr
	lea r8, ufo_update
	jmp array_forEach
ufo_updateAll endp

; in:
	; rdi - pointer to UFO
; out:
	; eax - 1 if UFO was destroyed, 0 else
ufo_update proc
	ret
ufo_update endp

ufo_drawAll proc
	lea rsi, ufos_arr
	lea r8, ufo_draw
	jmp array_forEach
ufo_drawAll endp

; in:
	; rdi - pointer to UFO
; out:
	; eax - 0 (UFO was not destroyed)
ufo_draw proc
	ret
ufo_draw endp



endif
