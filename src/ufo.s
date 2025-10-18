ifndef ufo_h
ufo_h = 1

include <globaldefs.inc>
include <windows.inc>

include <array.s>
include <screen.s>


Ufo struct
	pos         Point  <?>
	velocity    Vector <?>
	targ_pos    Point  <?>
	shoot_timer dd     ?
	frame_ind   dd     ?
	frame_ctr   dd     ?
	; turn_timer  dd    ?
Ufo ends

MAX_NUM_UFOS      = 4
UFO_NUM_FRAMES    = 4
UFO_FRAME_CTR_AMT = 6


.data

ufos_arr                Array { { ufos, 0 }, MAX_NUM_UFOS, sizeof Ufo }
ufo_spr_resource_name_0 byte  "UFOBIN0", 0
ufo_spr_resource_name_1 byte  "UFOBIN1", 0
ufo_spr_resource_name_2 byte  "UFOBIN2", 0
ufo_spr_resource_name_3 byte  "UFOBIN3", 0
ufo_resource_type       byte  "BIN", 0


.data?

ufos         Ufo MAX_NUM_UFOS dup (<>)
ufo_spr_data dq  ?
             dq  ?
             dq  ?
             dq  ?


.code

ufo_init proc
	push rbp
	mov rbp, rsp
	sub rsp, 200h

	xor rcx, rcx
	lea rdx, ufo_spr_resource_name_0
	lea r8, ufo_resource_type
	call FindResourceA
	xor rcx, rcx
	mov rdx, rax
	call LoadResource
	mov rcx, rax
	call LockResource
	mov [ufo_spr_data], rax
 
	xor rcx, rcx
	lea rdx, ufo_spr_resource_name_1
	lea r8, ufo_resource_type
	call FindResourceA
	xor rcx, rcx
	mov rdx, rax
	call LoadResource
	mov rcx, rax
	call LockResource
	mov [ufo_spr_data + 8], rax
 
	xor rcx, rcx
	lea rdx, ufo_spr_resource_name_2
	lea r8, ufo_resource_type
	call FindResourceA
	xor rcx, rcx
	mov rdx, rax
	call LoadResource
	mov rcx, rax
	call LockResource
	mov [ufo_spr_data + 16], rax
 
	xor rcx, rcx
	lea rdx, ufo_spr_resource_name_3
	lea r8, ufo_resource_type
	call FindResourceA
	xor rcx, rcx
	mov rdx, rax
	call LoadResource
	mov rcx, rax
	call LockResource
	mov [ufo_spr_data + 24], rax
 
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
	mov [rsi].Ufo.frame_ind, 0
	mov [rsi].Ufo.frame_ctr, UFO_FRAME_CTR_AMT
	
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
	dec [rdi].Ufo.frame_ctr
	jne frameCtrIncEnd
		mov [rdi].Ufo.frame_ctr, UFO_FRAME_CTR_AMT
		inc [rdi].Ufo.frame_ind
		and [rdi].Ufo.frame_ind, 11b
	frameCtrIncEnd:

	xor eax, eax
	ret
ufo_update endp

ufo_drawAll proc
	lea rsi, ufos_arr
	lea r8, ufo_draw
	jmp array_forEach
ufo_drawAll endp

; in:
	; rdi - pointer to ufo
ufo_destroy proc
	push rbx
	push rcx
	push rdx
	push r8

	xor r8, r8

	mov rbx, [rdi].Ufo.pos
	mov rcx, [rdi].Ufo.velocity
	mov edx, 36
	call shipShard_create

	mov rbx, [rdi].Ufo.pos
	mov rcx, [rdi].Ufo.velocity
	mov edx, 16
	add r8b, 256/5
	call shipShard_create

	mov rbx, [rdi].Ufo.pos
	mov rcx, [rdi].Ufo.velocity
	mov edx, 25
	add r8b, 256/5
	call shipShard_create

	mov rbx, [rdi].Ufo.pos
	mov rcx, [rdi].Ufo.velocity
	mov edx, 12
	add r8b, 256/5
	call shipShard_create

	mov rbx, [rdi].Ufo.pos
	mov rcx, [rdi].Ufo.velocity
	mov edx, 20
	add r8b, 256/5
	call shipShard_create

	lea rsi, ufos_arr
	call array_removeEl

	pop r8
	pop rdx
	pop rcx
	pop rbx
	ret
ufo_destroy endp

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
	mov eax, [rdi].Ufo.frame_ind
	shl eax, 3 ; x8
	lea rsi, ufo_spr_data
	add rsi, rax
	mov rsi, [rsi]
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
