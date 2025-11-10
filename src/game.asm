%ifndef game_h
%define game_h

%include "src/data/shake-offsets.inc"
%include "src/data/flicker-alphas.inc"

%include "src/global.asm"
%include "src/font.asm"
%include "src/fx/shard.asm"
%include "src/fx/ship-shard.asm"
%include "src/fx/fire.asm"
%include "src/fx/star.asm"
%include "src/bullet.asm"
%include "src/ship.asm"
%include "src/asteroid.asm"
%include "src/ufo.asm"


struc WaveData
	.num_large_asteroids:  resd 1
	.num_medium_asteroids: resd 1
	.num_small_asteroids:  resd 1
	.num_ufos:             resd 1
endstruc

NUM_FLASHES                    equ 8
FLASH_COUNTER_AMT              equ 9
GAME_NEXT_WAVE_COUNTER_AMT     equ 60 * 3
GAME_UFO_GEN_COUNTER_MIN_AMT   equ 60 * 3
GAME_UFO_GEN_COUNTER_RAND_MASK equ 01ffh
GAME_UFO_GEN_YPOS_LEEWAY       equ (SCREEN_HEIGHT / 2) + (SCREEN_HEIGHT / 4) ; SCREEN_HEIGHT * 0.75
GAME_START_NUM_LIVES           equ 4
GAME_LIVES_FLICKER_INC         equ 0080h
GAME_GAMEOVER_COUNTER_AMT      equ 60 * 4
GAME_PRESS_ANY_KEY_COUNTER_AMT equ 60 * 7
GAME_PRESS_ANY_KEY_Y           equ ((SCREEN_HEIGHT / 2) + 64) << 16

section .data

waves:
	istruc WaveData
		at .num_large_asteroids, dd 3
		at .num_medium_asteroids, dd 0
		at .num_small_asteroids, dd 0
		at .num_ufos, dd 0
	iend
	istruc WaveData
		at .num_large_asteroids, dd 4
		at .num_medium_asteroids, dd 1
		at .num_small_asteroids, dd 0
		at .num_ufos, dd 1
	iend
	istruc WaveData
		at .num_large_asteroids, dd 3
		at .num_medium_asteroids, dd 3
		at .num_small_asteroids, dd 0
		at .num_ufos, dd 2
	iend
	istruc WaveData
		at .num_large_asteroids, dd 1
		at .num_medium_asteroids, dd 5
		at .num_small_asteroids, dd 2
		at .num_ufos, dd 2
	iend
	istruc WaveData
		at .num_large_asteroids, dd 1
		at .num_medium_asteroids, dd 5
		at .num_small_asteroids, dd 5
		at .num_ufos, dd 2
	iend
	istruc WaveData
		at .num_large_asteroids, dd 1
		at .num_medium_asteroids, dd 3
		at .num_small_asteroids, dd 9
		at .num_ufos, dd 2
	iend
	istruc WaveData
		at .num_large_asteroids, dd 2
		at .num_medium_asteroids, dd 4
		at .num_small_asteroids, dd 10
		at .num_ufos, dd 3
	iend
	istruc WaveData
		at .num_large_asteroids, dd 2
		at .num_medium_asteroids, dd 5
		at .num_small_asteroids, dd 12
		at .num_ufos, dd 3
	iend
waves_end equ $

game_score_pos:
	istruc Point
		at .x, dd 64 << 16
		at .y, dd 64 << 16
	iend
game_lives_pos:
	istruc Point
		at .x, dd 64 << 16
		at .y, dd 160 << 16
	iend


section .bss

current_wave      resq    1
flash_counter     resd    1
ufo_gen_counter   resd    1
next_wave_counter resd    1

game_lives_points      resb Point_size * GAME_START_NUM_LIVES * SHIP_NUM_POINTS
game_lives_alphas      resb GAME_START_NUM_LIVES
game_lives_prev        resd    1 ; previous state of lives, for detecting change
game_lives_flicker_ind resw    1 ; 8.8 fixed point, upper byte is the actual index

game_score_prev      resd 1 ; previous state of score, for detecting change
game_score_shake_ind resd 1

game_show_gameover_counter      resd 1
game_show_gameover              resd 1
game_show_press_any_key_counter resd 1
game_gameover_flicker_inds      resd %strlen("GAMEOVER")


section .text

game_init:
	call ship_respawn
	lea rax, waves
	mov [current_wave], rax
	mov eax, [fg_color]
	mov [flash_color], eax

	mov [flash_counter], 0
	mov [ufo_gen_counter], 0
	mov [next_wave_counter], 0
	mov [game_lives_flicker_ind], 0

	mov [game_show_gameover_counter], 0
	mov [game_show_gameover], 0
	mov [game_show_press_any_key_counter], 0

	%assign i 0
	%rep %strlen("GAMEOVER")
		mov [game_gameover_flicker_inds + i * 4], 0
		%assign i i + 1
	%endrep

	mov eax, [lives]
	mov [game_lives_prev], eax

	mov [score], 0
	mov [game_score_prev], 0
	mov [lives], GAME_START_NUM_LIVES
	mov [screen_show_press_any_key], 0
	mov [is_in_gameover], 0
	mov [gameover_timer], 0
	mov [gameover_visibility], 0

	; for arr, <asteroids_arr, bullets_arr, ufos_arr, fires_arr, shards_arr, ship_shards_arr>
	; 	lea rsi, arr
	; 	call array_clear
	; endm
	
	lea rsi, asteroids_arr
	call array_clear
	lea rsi, bullets_arr
	call array_clear
	lea rsi, ufos_arr
	call array_clear
	lea rsi, fires_arr
	call array_clear
	lea rsi, shards_arr
	call array_clear
	lea rsi, ship_shards_arr
	call array_clear

	mov al, 0ffh
	%assign i 0
	%rep GAME_START_NUM_LIVES
		mov [game_lives_alphas + i], al
		%assign i i + 1
	%endrep

	; fall thru


game_initWave:
	push rbx
	push rdx
	push rsi
	push rdi
	push r15

	; mov rbx, (100 << (32 + 16)) or (500 << 16)
	; call ufo_create

	mov rsi, [current_wave]

	lea rdi, asteroid_shapes
	lea r15, asteroid_shapes_end

	%macro game_initWave_incAsteroidShapePtr 0
		add rdi, FatPtr_size
		cmp rdi, r15
		jl %%end
		lea rdi, asteroid_shapes
		%%end:
	%endmacro

	mov ecx, 3
	mov edx, [rsi + WaveData.num_large_asteroids]
	test edx, edx
	je .createLargeAsteroidsLoopEnd
	.createLargeAsteroidsLoop:
		call asteroid_createRand
		game_initWave_incAsteroidShapePtr
		dec edx
		jne .createLargeAsteroidsLoop
	.createLargeAsteroidsLoopEnd:

	dec ecx
	mov edx, [rsi + WaveData.num_medium_asteroids]
	test edx, edx
	je .createMediumAsteroidsLoopEnd
	.createMediumAsteroidsLoop:
		call asteroid_createRand
		game_initWave_incAsteroidShapePtr
		dec edx
		jne .createMediumAsteroidsLoop
	.createMediumAsteroidsLoopEnd:

	dec ecx
	mov edx, [rsi + WaveData.num_small_asteroids]
	test edx, edx
	je .createSmallAsteroidsLoopEnd
	.createSmallAsteroidsLoop:
		call asteroid_createRand
		game_initWave_incAsteroidShapePtr
		dec edx
		jne .createSmallAsteroidsLoop
	.createSmallAsteroidsLoopEnd:

	mov eax, [rsi + WaveData.num_ufos]
	mov [ufos_arr + Array.cap], eax

	mov rax, [current_wave]
	lea rdx, waves
	cmp rax, rdx
	je ._
	mov [flash_counter], FLASH_COUNTER_AMT
	mov [num_flashes_left], NUM_FLASHES
	._:
	call game_setUfoGenCounter

	pop r15
	pop rdi
	pop rsi
	pop rdx
	pop rbx
	ret


game_setUfoGenCounter:
	xor eax, eax
	rand ax
	and ax, GAME_UFO_GEN_COUNTER_RAND_MASK
	add eax, GAME_UFO_GEN_COUNTER_MIN_AMT
	mov [ufo_gen_counter], eax
	ret


game_setShipLivesPoints:
	lea r10, game_lives_pos
	xor r11, r11
	mov r12d, 00010000h

	%assign i 0
	%rep 4
		lea r8, ship_base_points
		lea r9, game_lives_points + (i * (Point_size * 5))
		call applyBasePointToPoint

		%rep 4
		add r8, BasePoint_size
		add r9, Point_size
		call applyBasePointToPoint
		%endrep
	
		mov eax, 36 << 16
		add [game_lives_pos + Point.x], eax
		%assign i i + 1
	%endrep

	ret


; in:
	; rdi - pointer to Input struct
game_tick:
	cmp [rdi + Input.buttons_pressed], 0
	je ._
		cmp [screen_show_press_any_key], 0
		je ._
		call title_init
		mov [mode], Mode_Title
		ret
	._:

	cmp [is_paused], 0
	jne .end

	cmp [is_in_gameover], 0
	jne ._1
	call ship_update
	._1:
	call bullet_updateAll
	call asteroid_updateAll
	call ufo_updateAll
	call fire_updateAll
	call shard_updateAll
	call shipShard_updateAll

	; flicker game over
	cmp [game_gameover_flicker_inds], 0
	je .gameoverFlickerEnd
		cmp [game_gameover_flicker_inds + 0 * 4], flicker_alphas_len
		jge ._8
		inc [game_gameover_flicker_inds + 0 * 4]
		._8:
		cmp [game_gameover_flicker_inds + 1 * 4], flicker_alphas_len
		jge ._9
		inc [game_gameover_flicker_inds + 1 * 4]
		._9:
		cmp [game_gameover_flicker_inds + 2 * 4], flicker_alphas_len
		jge ._10
		inc [game_gameover_flicker_inds + 2 * 4]
		._10:
		cmp [game_gameover_flicker_inds + 3 * 4], flicker_alphas_len
		jge ._11
		inc [game_gameover_flicker_inds + 3 * 4]
		._11:
		cmp [game_gameover_flicker_inds + 4 * 4], flicker_alphas_len
		jge ._12
		inc [game_gameover_flicker_inds + 4 * 4]
		._12:
		cmp [game_gameover_flicker_inds + 5 * 4], flicker_alphas_len
		jge ._13
		inc [game_gameover_flicker_inds + 5 * 4]
		._13:
		cmp [game_gameover_flicker_inds + 6 * 4], flicker_alphas_len
		jge ._14
		inc [game_gameover_flicker_inds + 6 * 4]
		._14:
		cmp [game_gameover_flicker_inds + 7 * 4], flicker_alphas_len
		jge ._15
		inc [game_gameover_flicker_inds + 7 * 4]
		._15:
	.gameoverFlickerEnd:

	; gameover counter
	cmp [game_show_gameover_counter], 0
	je .gameoverCounterEnd
		dec [game_show_gameover_counter]
		jne .gameoverCounterEnd
		inc [game_show_gameover]
		%assign i 0
		%rep 8
			rand eax
			and eax, 11111b
			inc eax
			mov [game_gameover_flicker_inds + i * 4], eax
			%assign i i + 1
		%endrep
	.gameoverCounterEnd:

	; "press any key" counter
	cmp dword [game_show_press_any_key_counter], 0
	je .pressAnyKeyEnd
		dec dword [game_show_press_any_key_counter]
		sete byte [screen_show_press_any_key]
	.pressAnyKeyEnd:

	; lives counter
	mov eax, [lives]
	cmp [game_lives_prev], eax
	je .livesCheckEnd
		setge byte [game_lives_flicker_ind + 1]
		mov [game_lives_prev], eax
		test eax, eax
		jne .livesCheckEnd
			mov dword [game_show_gameover_counter], GAME_GAMEOVER_COUNTER_AMT
			mov dword [game_show_press_any_key_counter], GAME_PRESS_ANY_KEY_COUNTER_AMT
	.livesCheckEnd:

	; lives flicker
	cmp byte [game_lives_flicker_ind + 1], 0
	je ._2
		xor eax, eax
		mov al, byte [game_lives_flicker_ind + 1]
		lea rsi, flicker_alphas
		mov dl, [rsi + rax]
		mov ebx, [lives]
		lea rsi, game_lives_alphas
		mov [rsi + rbx], dl
		mov ax, GAME_LIVES_FLICKER_INC
		add [game_lives_flicker_ind], ax
		xor eax, eax
		mov al, byte [game_lives_flicker_ind + 1]
		cmp eax, flicker_alphas_len
		jl ._2
		mov dword [game_lives_flicker_ind], 0
	._2:

	; score bounce update
	cmp dword [game_score_shake_ind], 0
	je ._3
		inc dword [game_score_shake_ind]
		cmp dword [game_score_shake_ind], bounce_offset_len
		jl ._3
		mov dword [game_score_shake_ind], 0
	._3:

	; score bounce
	mov eax, [score]
	cmp [game_score_prev], eax
	je .scoreCheckEnd
		; jg ._ ; I don't know why it would go down but def don't want to bounce it in that case
			mov dword [game_score_shake_ind], 1
		; ._:
		mov [game_score_prev], eax
	.scoreCheckEnd:

	; gameover counter
	cmp dword [gameover_timer], 0
	je ._4
		dec dword [gameover_timer]
	._4:

	; flash asteroids
	cmp dword [num_flashes_left], 0
	je .flashEnd
	dec dword [flash_counter]
	jne .flashEnd
		mov dword [flash_counter], FLASH_COUNTER_AMT
		dec [num_flashes_left]
		bt dword [num_flashes_left], 0
		jc ._5
			mov eax, [fg_color]
			jmp .flashColStore
		._5:
			mov eax, [dim_color]
		.flashColStore:
		mov [flash_color], eax
	.flashEnd:

	; generate UFOs
	dec dword [ufo_gen_counter]
	jne .ufoGenEnd
		call game_setUfoGenCounter

		; x
		rand eax
		test eax, eax
		js .ufoGenLeftSide
		;ufoGenRightSide:
			mov ebx, (SCREEN_WIDTH + UFO_BBOX_WIDTH / 2) - 1
			jmp .ufoGenRest
		.ufoGenLeftSide:
			mov ebx, (-UFO_BBOX_WIDTH / 2) & 0ffffffffh
		.ufoGenRest:

		; y
		mov ecx, GAME_UFO_GEN_YPOS_LEEWAY
		rand eax
		and eax, 7fffh
		cdq
		div ecx
		add edx, (SCREEN_HEIGHT / 2) - (GAME_UFO_GEN_YPOS_LEEWAY / 2)
		shl rdx, 32

		or rbx, rdx
		shl rbx, 16
		call ufo_create
	.ufoGenEnd:

	; wave complete?
	cmp dword [next_wave_counter], 0
	je .decWaveCounterEnd
		dec dword [next_wave_counter]
		jne .nextWaveLogicEnd
		add qword [current_wave], WaveData_size
		lea rax, waves_end
		cmp [current_wave], rax
		jl ._6
			sub qword [current_wave], WaveData_size
		._6:
		call game_initWave
		jmp .nextWaveLogicEnd
	.decWaveCounterEnd:
	cmp dword [asteroids_arr + Array.data + FatPtr.len], 0
	jne .nextWaveLogicEnd
		mov dword [next_wave_counter], GAME_NEXT_WAVE_COUNTER_AMT
	.nextWaveLogicEnd:

	.end:
	ret

game_draw:
	cmp dword [is_in_gameover], 0
	jne ._
	call ship_draw
	._:
	call bullet_drawAll
	call asteroid_drawAll
	call ufo_drawAll
	call fire_drawAll
	call shard_drawAll
	call shipShard_drawAll
	call game_drawScore
	call game_drawLives
	call game_drawGameOver
	mov dword [font_current_char_pos + Point.y], GAME_PRESS_ANY_KEY_Y
	call screen_drawPressAnyKey
	ret


game_drawScore:
	push rbx
	push rdx
	push rsi
	push r8
	push r9
	push r10 ; num chars drawn
	push r11 ; t (100,000 -> 1)
	push r12 ; char index (for bouncing)

	lea rsi, font_digits_spr_data
	mov r8d, [fg_color]
	lea r9, font_current_char_rect
	lea r14, screen_draw3difiedPixelOnscreenVerified

	mov rax, [game_score_pos]
	mov [font_current_char_pos], rax

	mov dword [font_current_char_rect + Rect.pos + Point.x], 0
	mov dword [font_current_char_rect + Rect.pos + Point.y], 0
	mov dword [font_current_char_rect + Rect.dim + Dim.w], FONT_DIGIT_WIDTH
	mov dword [font_current_char_rect + Rect.dim + Dim.h], FONT_DIGIT_HEIGHT

	xor r10, r10
	mov r11d, 1000000
	mov r12d, [game_score_shake_ind]

	.charLoop:
		; t /= 10
		mov eax, r11d
		mov ebx, 10
		cdq
		div ebx
		mov r11d, eax

		; calc digit -> edx
		mov eax, [score]
		cdq
		div r11d
		mov ebx, 10
		cdq
		div ebx

		; if t != 1 and !digit and !numDigitsDrawn then continue
		cmp r11d, 1
		je ._
		test edx, edx
		jne ._
		test r10d, r10d
		je .charLoopNext
		._:

		; reset onscreen y
		mov eax, [game_score_pos + Point.y]
		mov [font_current_char_pos + Point.y], eax

		; bounce
		lea rax, bounce_offsets
		; mov r12, 0
		xor ebx, ebx
		mov bl, [rax + r12]
		shl ebx, 16
		sub [font_current_char_pos + Point.y], ebx

		mov ebx, [font_current_char_rect + Rect.dim + Dim.w]
		imul edx, ebx
		mov [font_current_char_rect + Rect.pos + Point.x], edx
		lea rdx, font_current_char_pos
		call screen_draw1bppSprite

		add dword [font_current_char_pos + Point.x], FONT_DIGIT_KERNING << 16
		saturatingSub32 r12d, 4

		; if numDigitsDrawn == 4 then draw comma
		inc r10d
		cmp r11d, 1000
		jne ._1
			; draw comma
			push rsi
			push r9

			lea r9, font_comma_rect
			lea rsi, font_comma_spr_data
			add dword [font_current_char_pos + Point.y], (FONT_DIGIT_HEIGHT - 24) << 16
			sub dword [font_current_char_pos + Point.x], 12 << 16
			; lea rdx, font_current_char_pos
			call screen_draw1bppSprite
			sub dword [font_current_char_pos + Point.y], (FONT_DIGIT_HEIGHT - 24) << 16
			add dword [font_current_char_pos + Point.x], 26 << 16

			pop r9
			pop rsi
		._1:

		.charLoopNext:
		cmp r11d, 1
		jne .charLoop

	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rsi
	pop rdx
	pop rbx
	ret


%macro game_setLivesAlphas 0
	%assign i 0
	%rep GAME_START_NUM_LIVES
		
	%endrep
%endmacro

game_drawLives:
	game_setLivesAlphas
	mov r8d, [fg_color]

	%assign i 0
	%rep GAME_START_NUM_LIVES
		xor eax, eax
		mov al, [game_lives_alphas + i]
		shl eax, 24
		and r8d, 00ffffffh
		or r8d, eax
		screen_mDrawLine (game_lives_points + (i * (5 * Point_size))) + Point_size*0, (game_lives_points + (i * (5 * Point_size))) + Point_size*1
		screen_mDrawLine (game_lives_points + (i * (5 * Point_size))) + Point_size*0, (game_lives_points + (i * (5 * Point_size))) + Point_size*2
		screen_mDrawLine (game_lives_points + (i * (5 * Point_size))) + Point_size*3, (game_lives_points + (i * (5 * Point_size))) + Point_size*4
		%assign i i + 1
	%endrep
	ret


GAMEOVER_CHAR_KERNING equ 16
GAMEOVER_CHAR_WIDTH   equ FONT_LG_CHAR_WIDTH + GAMEOVER_CHAR_KERNING
GAMEOVER_FULL_WIDTH   equ %strlen("GAMEOVER") * GAMEOVER_CHAR_WIDTH
GAMEOVER_FIRST_X      equ (((SCREEN_WIDTH / 2) - (GAMEOVER_FULL_WIDTH / 2)) + (FONT_LG_CHAR_WIDTH / 2)) << 16

gameoverUs:
	dw FONT_LG_X_G
	dw FONT_LG_X_A
	dw FONT_LG_X_M
	dw FONT_LG_X_E
	dw FONT_LG_X_O
	dw FONT_LG_X_V
	dw FONT_LG_X_E
	dw FONT_LG_X_R

game_drawGameOver:
	cmp dword [game_show_gameover], 0
	je ._ret

	push rbx
	push rcx
	push rsi
	push rdi

	; cmp [game_show_gameover], 0
	; je .end

	lea rdx, font_current_char_pos
	lea rsi, font_large_spr_data
	mov r8d, [fg_color]
	lea r9, font_current_char_rect
	lea r14, screen_setPixelOnscreenVerified

	mov dword [font_current_char_rect + Rect.pos + Point.y], 0
	mov dword [font_current_char_rect + Rect.dim + Dim.w], FONT_LG_CHAR_WIDTH
	mov dword [font_current_char_rect + Rect.dim + Dim.h], FONT_LG_CHAR_HEIGHT
	mov dword [font_current_char_pos + Point.y], ((SCREEN_HEIGHT / 2) - (FONT_LG_CHAR_HEIGHT / 2)) << 16
	mov dword [font_current_char_pos + Point.x], GAMEOVER_FIRST_X

	xor ecx, ecx
	.charLoop:
		; set U coordinate of char sprite
		lea rdi, gameoverUs
		xor eax, eax
		mov ax, cx
		shl ax, 1
		mov ax, [rdi + rax]
		mov [font_current_char_rect + Rect.pos + Point.x], eax

		; set alpha of char
		lea rdi, game_gameover_flicker_inds
		mov eax, ecx
		shl eax, 2
		mov eax, [rdi + rax]

		lea rbx, flicker_alphas
		mov bl, [rbx + rax]

		xor eax, eax
		mov al, 0ffh
		sub al, bl
		shl eax, 24
		and r8d, 00ffffffh
		or r8d, eax

		; rdx - pointer to onscreen Point to draw sprite (16.16 fixed point)
		; rsi - pointer to beginning of sprite data
		; r8d - color
		; r9  - pointer to in-spritesheet Rect, dimensions of sprite
		; r14 - pointer to pixel plotting routine to call
		call screen_draw1bppSprite

		add dword [font_current_char_pos + Point.x], GAMEOVER_CHAR_WIDTH << 16
		cmp ecx, 3
		jne ._
			add dword [font_current_char_pos + Point.x], GAMEOVER_CHAR_KERNING << 16 ; add the space
		._:

		inc ecx
		cmp ecx, 8
		jl .charLoop

	.end:
	pop rdi
	pop rsi
	pop rcx
	pop rbx
	._ret:
	ret



%endif

