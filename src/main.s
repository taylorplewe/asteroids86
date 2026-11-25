include globaldefs.inc
include global.s
; include sdl\defs.inc

include data\flicker-alphas.inc
include common.s
include screen.s
include font.s

include game.s
include title.s

include windows\platform.s


.data

window_title byte "asteroids86", 0
icon_path    byte "art\asteroid_512.bmp", 0


.data?

ticks     dq    ?
is_paused dd    ?


.code

main proc
	push rbp
	mov rbp, rsp
	sub rsp, 200h
	and rsp, not 8h

	call star_generateAll
	call font_initSprData
	call ufo_initSprData
	call game_setShipLivesPoints
	call title_init
	mov [mode], Mode_Title

	call windows_init

	mov [frame_counter], 0
	mov [is_running], 1

	mainLoop:
	    ; get ticks possibly

		; mov [input].buttons_down, 0

		call windows_update
		cmp [is_running], 0
		je quit

		; set pressed & released keys
		; pressed = (down ^ prev) & down
		; released = (down ^ prev) & prev
		mov eax, [input].buttons_down
		mov ebx, [keys_prev]
		xor ebx, eax
		mov ecx, ebx
		and ecx, [keys_prev]
		mov [input].buttons_released, ecx
		and ebx, [input].buttons_down
		mov [input].buttons_pressed, ebx
		mov [keys_prev], eax

		bt [input].buttons_pressed, Keys_Pause
		jnc @f
			xor [is_paused], 1
		@@:

		mov [event_bus], 0

		lea rdi, input
		cmp [mode], Mode_Game
		je doGameTick
			call title_tick
			jmp ticksEnd
		doGameTick:
			call game_tick
		ticksEnd:

		; rumble gamepad for events that happened this frame
		bt [event_bus], Event_Fire
		jnc @f
			; mov rcx, [gamepad]
			; mov dx, 8000h
			; mov r8w, 0
			; mov r9d, 50
			; call SDL_RumbleGamepad
		@@:
		bt [event_bus], Event_ShipDestroy
		jnc @f
			; mov rcx, [gamepad]
			; mov dx, 3fffh
			; mov r8w, 0afffh
			; mov r9d, 700
			; call SDL_RumbleGamepad
		@@:

		call draw

		; 60fps
		; call SDL_GetTicks
		sub rax, qword ptr [ticks]
		mov rcx, 1000 / 60
		sub rcx, rax
		js delayEnd ; more than 1/60 of a second has already elapsed, next frame
		; call SDL_Delay
		delayEnd:

		inc [frame_counter]
		jmp mainLoop

	quit:

	call ExitProcess

	mov rsp, rbp
	pop rbp
	xor eax, eax
	ret
main endp

draw proc
	call screen_clearPixelBuffer

	call star_drawAll

	cmp [mode], Mode_Game
	je doGameDraw
		call title_draw
		jmp drawsEnd
	doGameDraw:
		call game_draw
	drawsEnd:

	call windows_draw

	ret
draw endp


end
