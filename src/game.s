ifndef game_h
game_h = 1

include <data\shake-offsets.inc>
include <data\flicker-alphas.inc>

include <global.s>
include <font.s>
include <fx\shard.s>
include <fx\ship-shard.s>
include <fx\fire.s>
include <bullet.s>
include <ship.s>
include <asteroid.s>
include <ufo.s>


WaveData struct
	num_large_asteroids  dd ?
	num_medium_asteroids dd ?
	num_small_asteroids  dd ?
	num_ufos             dd ?
WaveData ends

NUM_FLASHES                    = 8
FLASH_COUNTER_AMT              = 9
GAME_NEXT_WAVE_COUNTER_AMT     = 60 * 3
GAME_UFO_GEN_COUNTER_MIN_AMT   = 60 * 3
GAME_UFO_GEN_COUNTER_RAND_MASK = 01ffh
GAME_UFO_GEN_YPOS_LEEWAY       = (SCREEN_HEIGHT / 2) + (SCREEN_HEIGHT / 4) ; SCREEN_HEIGHT * 0.75
GAME_START_NUM_LIVES           = 4
GAME_LIVES_FLICKER_INC         = 0080h

.data

waves          WaveData { 3, 0, 0, 0 }, { 4, 1, 0, 1 }, { 3, 3, 0, 2 }, { 1, 5, 2, 2 }, { 1, 5, 5, 2 }, { 1, 3, 9, 2 }, { 2, 4, 10, 3 }, { 2, 5, 12, 3 }
waves_end = $

game_score_pos    Point { 64 shl 16, 64 shl 16 }
game_lives_pos    Point { 64 shl 16, 160 shl 16 }
current_char_rect Rect  { { 0, 0 }, { FONT_DIGIT_WIDTH, FONT_DIGIT_HEIGHT } }


.data?

current_wave           dq    ?
flash_counter          dd    ?
ufo_gen_counter        dd    ?
next_wave_counter      dd    ?
current_char_pos       Point <>

game_lives_points      Point GAME_START_NUM_LIVES * SHIP_NUM_POINTS dup (<>)
game_lives_alphas      db    GAME_START_NUM_LIVES dup (?)
game_lives_prev        dd    ? ; previous state of lives, for detecting change
game_lives_flicker_ind dw    ? ; 8.8 fixed point, upper byte is the actual index

game_score_prev        dd    ? ; previous state of score, for detecting change
game_score_shake_ind   dd    ?


.code

game_init proc
	call ufo_init
	call game_setShipLivesPoints
	call ship_respawn
	lea rax, waves
	mov [current_wave], rax
	mov eax, [fg_color]
	mov [flash_color], eax

	mov [score], 0
	mov [lives], GAME_START_NUM_LIVES

	mov al, 0ffh
	i = 0
	repeat GAME_START_NUM_LIVES
		mov [game_lives_alphas + i], al
		i = i + 1
	endm

	; fall thru
game_init endp

game_initWave proc
	push rbx
	push rdx
	push rsi
	push rdi
	push r15

	; mov rbx, (100 shl (32 + 16)) or (500 shl 16)
	; call ufo_create

	mov rsi, [current_wave]

	lea rdi, asteroid_shapes
	lea r15, asteroid_shapes_end

	game_initWave_incAsteroidShapePtr macro
		local _end
		add rdi, sizeof FatPtr
		cmp rdi, r15
		jl _end
		lea rdi, asteroid_shapes
		_end:
	endm

	mov ecx, 3
	mov edx, [rsi].WaveData.num_large_asteroids
	test edx, edx
	je createLargeAsteroidsLoopEnd
	createLargeAsteroidsLoop:
		call asteroid_createRand
		game_initWave_incAsteroidShapePtr
		dec edx
		jne createLargeAsteroidsLoop
	createLargeAsteroidsLoopEnd:

	dec ecx
	mov edx, [rsi].WaveData.num_medium_asteroids
	test edx, edx
	je createMediumAsteroidsLoopEnd
	createMediumAsteroidsLoop:
		call asteroid_createRand
		game_initWave_incAsteroidShapePtr
		dec edx
		jne createMediumAsteroidsLoop
	createMediumAsteroidsLoopEnd:

	dec ecx
	mov edx, [rsi].WaveData.num_small_asteroids
	test edx, edx
	je createSmallAsteroidsLoopEnd
	createSmallAsteroidsLoop:
		call asteroid_createRand
		game_initWave_incAsteroidShapePtr
		dec edx
		jne createSmallAsteroidsLoop
	createSmallAsteroidsLoopEnd:

	mov eax, [rsi].WaveData.num_ufos
	mov [ufos_arr].cap, eax

	mov rax, [current_wave]
	lea rdx, waves
	cmp rax, rdx
	je @f
	mov [flash_counter], FLASH_COUNTER_AMT
	mov [num_flashes_left], NUM_FLASHES
	@@:
	call game_setUfoGenCounter

	pop r15
	pop rdi
	pop rsi
	pop rdx
	pop rbx
	ret
game_initWave endp

game_setUfoGenCounter proc
	xor eax, eax
	rand ax
	and ax, GAME_UFO_GEN_COUNTER_RAND_MASK
	add eax, GAME_UFO_GEN_COUNTER_MIN_AMT
	mov [ufo_gen_counter], eax
	ret
game_setUfoGenCounter endp

game_setShipLivesPoints proc
	lea r10, game_lives_pos
	xor r11, r11
	mov r12d, 00010000h

	i = 0
	repeat 4
		lea r8, ship_base_points
		lea r9, game_lives_points + (i * (sizeof Point * 5))
		call applyBasePointToPoint

		repeat 4
		add r8, sizeof BasePoint
		add r9, sizeof Point
		call applyBasePointToPoint
		endm
	
		mov eax, 36 shl 16
		add [game_lives_pos].x, eax
		i = i + 1
	endm

	ret
game_setShipLivesPoints endp

; in:
	; rdi to Keys struct of keys pressed
game_tick proc
	cmp [is_paused], 0
	jne draw

	cmp [is_in_gameover], 0
	jne @f
	call ship_update
	@@:
	call bullet_updateAll
	call asteroid_updateAll
	call ufo_updateAll
	call fire_updateAll
	call shard_updateAll
	call shipShard_updateAll

	draw:
	cmp [is_in_gameover], 0
	jne @f
	call ship_draw
	@@:
	call bullet_drawAll
	call asteroid_drawAll
	call ufo_drawAll
	call fire_drawAll
	call shard_drawAll
	call shipShard_drawAll
	call game_drawScore
	call game_drawLives

	; lives counter
	mov eax, [lives]
	cmp [game_lives_prev], eax
	je livesCheckEnd
		jl @f
			mov byte ptr [game_lives_flicker_ind + 1], 1
		@@:
		mov [game_lives_prev], eax
	livesCheckEnd:

	; lives flicker
	cmp byte ptr [game_lives_flicker_ind + 1], 0
	je @f
		xor eax, eax
		mov al, byte ptr [game_lives_flicker_ind + 1]
		lea rsi, flicker_alphas
		mov dl, [rsi + rax]
		mov ebx, [lives]
		lea rsi, game_lives_alphas
		mov [rsi + rbx], dl
		mov ax, GAME_LIVES_FLICKER_INC
		add [game_lives_flicker_ind], ax
		xor eax, eax
		mov al, byte ptr [game_lives_flicker_ind + 1]
		cmp eax, flicker_alphas_len
		jl @f
		mov [game_lives_flicker_ind], 0
	@@:

	; score bounce update
	cmp [game_score_shake_ind], 0
	je @f
		inc [game_score_shake_ind]
		cmp [game_score_shake_ind], bounce_offset_len
		jl @f
		mov [game_score_shake_ind], 0
	@@:

	; score bounce
	mov eax, [score]
	cmp [game_score_prev], eax
	je scoreCheckEnd
		; jg @f ; I don't know why it would go down but def don't want to bounce it in that case
			mov [game_score_shake_ind], 1
		; @@:
		mov [game_score_prev], eax
	scoreCheckEnd:

	; gameover counter
	cmp [gameover_timer], 0
	je @f
		dec [gameover_timer]
	@@:

	; flash asteroids
	cmp [num_flashes_left], 0
	je flashEnd
	dec [flash_counter]
	jne flashEnd
		mov [flash_counter], FLASH_COUNTER_AMT
		dec [num_flashes_left]
		bt [num_flashes_left], 0
		jc @f
			mov eax, [fg_color]
			jmp flashColStore
		@@:
			mov eax, [dim_color]
		flashColStore:
		mov [flash_color], eax
	flashEnd:

	; generate UFOs
	dec [ufo_gen_counter]
	jne ufoGenEnd
		call game_setUfoGenCounter

		; x
		rand eax
		test eax, eax
		js ufoGenLeftSide
		;ufoGenRightSide:
			mov ebx, (SCREEN_WIDTH + UFO_BBOX_WIDTH / 2) - 1
			jmp ufoGenRest
		ufoGenLeftSide:
			mov ebx, -UFO_BBOX_WIDTH / 2
		ufoGenRest:

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
	ufoGenEnd:

	; wave complete?
	cmp [next_wave_counter], 0
	je decWaveCounterEnd
		dec [next_wave_counter]
		jne nextWaveLogicEnd
		add [current_wave], sizeof WaveData
		lea rax, waves_end
		cmp [current_wave], rax
		jl @f
			sub [current_wave], sizeof WaveData
		@@:
		call game_initWave
		jmp nextWaveLogicEnd
	decWaveCounterEnd:
	cmp [asteroids_arr].data.len, 0
	jne nextWaveLogicEnd
		mov [next_wave_counter], GAME_NEXT_WAVE_COUNTER_AMT
	nextWaveLogicEnd:

	ret
game_tick endp

game_drawScore proc
	push rbx
	push rdx
	push rsi
	push r8
	push r9
	push r10 ; num chars drawn
	push r11 ; t (100,000 -> 1)
	push r12 ; char index (for bouncing)

	; screen_draw1bppSprite:
	; rdx - pointer to onscreen Point to draw sprite (16.16 fixed point)
	; rsi - pointer to beginning of sprite data
	; r8d - color
	; r9  - pointer to in-spritesheet Rect, dimensions of sprite
	; r14 - pointer to pixel plotting routine to call

	mov rsi, [font_digits_spr_data]
	mov r8d, [fg_color]
	lea r9, current_char_rect
	lea r14, screen_draw3difiedPixelOnscreenVerified

	mov rax, [game_score_pos]
	mov [current_char_pos], rax

	xor r10, r10
	mov r11d, 1000000
	mov r12d, [game_score_shake_ind]

	charLoop:
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
		je @f
		test edx, edx
		jne @f
		test r10d, r10d
		je charLoopNext
		@@:

		; reset onscreen y
		mov eax, [game_score_pos].y
		mov [current_char_pos].y, eax

		; bounce
		; brk
		lea rax, bounce_offsets
		; mov r12, 0
		xor ebx, ebx
		mov bl, [rax + r12]
		shl ebx, 16
		sub [current_char_pos].y, ebx

		mov ebx, [current_char_rect].dim.w
		imul edx, ebx
		mov [current_char_rect].pos.x, edx
		lea rdx, current_char_pos
		call screen_draw1bppSprite

		add [current_char_pos].x, FONT_KERNING shl 16
		saturatingSub32 r12d, 4

		; if numDigitsDrawn == 4 then draw comma
		inc r10d
		cmp r11d, 1000
		jne @f
			; draw comma
			push rsi
			push r9

			lea r9, font_comma_rect
			mov rsi, [font_comma_spr_data]
			add [current_char_pos].y, (FONT_DIGIT_HEIGHT - 24) shl 16
			sub [current_char_pos].x, 12 shl 16
			; lea rdx, current_char_pos
			call screen_draw1bppSprite
			sub [current_char_pos].y, (FONT_DIGIT_HEIGHT - 24) shl 16
			add [current_char_pos].x, 26 shl 16

			pop r9
			pop rsi
		@@:

		charLoopNext:
		cmp r11d, 1
		jne charLoop

	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rsi
	pop rdx
	pop rbx
	ret
game_drawScore endp

game_setLivesAlphas macro
	i = 0
	repeat GAME_START_NUM_LIVES
		
	endm
endm

game_drawLives proc
	game_setLivesAlphas
	mov r8d, [fg_color]

	i = 0
	repeat GAME_START_NUM_LIVES
		xor eax, eax
		mov al, [game_lives_alphas + i]
		shl eax, 24
		and r8d, 00ffffffh
		or r8d, eax
		screen_mDrawLine (game_lives_points + (i * (5 * sizeof Point))) + sizeof Point*0, (game_lives_points + (i * (5 * sizeof Point))) + sizeof Point*1
		screen_mDrawLine (game_lives_points + (i * (5 * sizeof Point))) + sizeof Point*0, (game_lives_points + (i * (5 * sizeof Point))) + sizeof Point*2
		screen_mDrawLine (game_lives_points + (i * (5 * sizeof Point))) + sizeof Point*3, (game_lives_points + (i * (5 * sizeof Point))) + sizeof Point*4
		i = i + 1
	endm
	ret
game_drawLives endp


endif
