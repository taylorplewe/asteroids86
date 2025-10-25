ifndef game_h
game_h = 1

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

.data

waves          WaveData { 3, 0, 0, 0 }, { 4, 1, 0, 1 }, { 3, 3, 0, 2 }, { 1, 5, 2, 2 }, { 1, 5, 5, 2 }, { 1, 3, 9, 2 }, { 2, 4, 10, 3 }, { 2, 5, 12, 3 }
waves_end = $

game_score_pos    Point { 64 shl 16, 64 shl 16 }
current_char_rect Rect  { { 0, 0 }, { FONT_DIGIT_WIDTH, FONT_DIGIT_HEIGHT } }


.data?

current_wave      dq ?
flash_counter     dd ?
ufo_gen_counter   dd ?
next_wave_counter dd ?
current_char_pos  Point <>


.code

game_init proc
	call ufo_init
	call ship_respawn
	lea rax, waves
	mov [current_wave], rax
	mov eax, [fg_color]
	mov [flash_color], eax

	mov [score], 0
	mov [lives], GAME_START_NUM_LIVES
	
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

; in:
	; rdi to Keys struct of keys pressed
game_tick proc
	cmp [is_paused], 0
	jne draw

	call ship_update
	call bullet_updateAll
	call asteroid_updateAll
	call ufo_updateAll
	call fire_updateAll
	call shard_updateAll
	call shipShard_updateAll

	draw:
	call ship_draw
	call bullet_drawAll
	call asteroid_drawAll
	call ufo_drawAll
	call fire_drawAll
	call shard_drawAll
	call shipShard_drawAll
	call game_drawScore

	; gameover counter
	cmp [gameover_counter], 0
	je @f
		dec [gameover_counter]
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

	; rdx - pointer to onscreen Point to draw sprite (16.16 fixed point)
	 ; rsi - pointer to beginning of sprite data
	 ; r8d - color
	 ; r9  - pointer to in-spritesheet Rect, dimensions of sprite
	 ; r14 - pointer to pixel plotting routine to call

	mov rsi, [font_digits_spr_data]
	mov r8d, [fg_color]
	lea r9, current_char_rect
	lea r14, screen_draw3difiedPixelOnscreenVerified

	mov rax, qword ptr [game_score_pos]
	mov qword ptr [current_char_pos], rax

	; 100s spot: (score / 100) % 10
	; 10s spot:  (score / 10) % 10
	; 1s spot:   score % 10

	; 100s
	mov eax, [score]
	mov ebx, 100
	cdq
	div ebx
	mov ebx, 10
	cdq
	div ebx
	; edx is now our desired decmial digit
	mov ebx, [current_char_rect].dim.w
	imul edx, ebx
	mov [current_char_rect].pos.x, edx
	lea rdx, current_char_pos
	call screen_draw1bppSprite

	add [current_char_pos].x, (FONT_DIGIT_WIDTH + FONT_KERNING) shl 16

	; 10s
	mov eax, [score]
	mov ebx, 10
	cdq
	div ebx
	mov ebx, 10
	cdq
	div ebx
	mov ebx, [current_char_rect].dim.w
	imul edx, ebx
	mov [current_char_rect].pos.x, edx
	lea rdx, current_char_pos
	call screen_draw1bppSprite

	add [current_char_pos].x, (FONT_DIGIT_WIDTH + FONT_KERNING) shl 16

	; 1s
	mov eax, [score]
	mov ebx, 10
	cdq
	div ebx
	mov ebx, [current_char_rect].dim.w
	imul edx, ebx
	mov [current_char_rect].pos.x, edx
	lea rdx, current_char_pos
	call screen_draw1bppSprite

	pop r9
	pop r8
	pop rsi
	pop rdx
	pop rbx
	ret
game_drawScore endp


endif
