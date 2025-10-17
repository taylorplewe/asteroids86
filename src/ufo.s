ifndef ufo_h
ufo_h = 1

include <globaldefs.inc>
include <windows.inc>

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

ufos_arr          Array { { ufos, 0 }, MAX_NUM_UFOS, sizeof Ufo }
ufo_resource_name byte  "UFOBIN", 0
ufo_resource_type byte  "BIN", 0


.data?

ufos           Ufo MAX_NUM_UFOS dup (<>)
ufo_bin_ptr    dq  ?
ufo_sprite_dim Dim {}


.code

ufo_init proc
	push rbp
	mov rbp, rsp
	sub rsp, 200h

	xor rcx, rcx
	lea rdx, ufo_resource_name
	lea r8, ufo_resource_type
	call FindResourceA

	xor rcx, rcx
	mov rdx, rax
	call LoadResource

	mov rcx, rax
	call LockResource

	mov rsi, rax
	mov eax, [rsi].Dim.w
	mov [ufo_sprite_dim].w, eax
	mov eax, [rsi].Dim.h
	mov [ufo_sprite_dim].h, eax
	add rsi, sizeof Dim
	mov [ufo_bin_ptr], rsi

	mov rsp, rbp
	pop rbp
	ret
ufo_init endp

; in:
	; rbx - pos
ufo_create proc
	lea rsi, ufos_arr
	call array_push
	test eax, eax
	je _end

	mov rsi, rax
	mov qword ptr [rsi].Ufo.pos, rbx
	
	_end:
	ret
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
	xor eax, eax
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
	; rdx - pointer to Pos
	; rsi - pointer to sprite data
	; r9  - pointer to sprite Dim
	; r8d - color
	push rdx
	push rsi
	push r8
	push r9

	lea rdx, [rdi].Ufo.pos
	mov rsi, [ufo_bin_ptr]
	lea r9, ufo_sprite_dim
	mov r8d, [fg_color]
	call screen_draw1bppSprite

	xor eax, eax
	pop r9
	pop r8
	pop rsi
	pop rdx
	ret
ufo_draw endp



endif
