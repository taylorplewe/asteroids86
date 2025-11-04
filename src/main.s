include <windows\defs.inc>
include <globaldefs.inc>
include <sdl\defs.inc>

include <data\flicker-alphas.inc>
include <common.s>
include <screen.s>
include <font.s>

include <game.s>
include <title.s>


.data

window_title byte "asteroids86", 0
icon_path    byte "art\asteroid_512.bmp", 0


.data?

; SDL stuff
window   dq ?
renderer dq ?
surface  dq ?
texture  dq ?
icon     dq ?
event    db 2048 dup (?)

ticks     dq   ?
keys_down Keys ?
is_paused dd   ?

joystick_ids dq ?
gamepad      dq ?


.code

setWindowIcon macro
	lea rcx, icon_path
	call SDL_LoadBMP
	; rax = *SDL_Surface

	mov [icon], rax

	mov rdx, rax
	mov rcx, [window]
	call SDL_SetWindowIcon
	
endm

main proc
	push rbp
	mov rbp, rsp
	sub rsp, 200h

	call star_generateAll

	call font_initSprData
	call ufo_initSprData
	call game_setShipLivesPoints
	call title_init
	mov [mode], Mode_Title

	mov ecx, SDL_INIT_VIDEO or SDL_INIT_GAMEPAD
	call SDL_Init

	; SDL_GetGamepads
	xor ecx, ecx
	call SDL_GetGamepads
	cmp dword ptr [rax], 0
	je gamepadInitEnd
		mov [joystick_ids], rax
		mov ecx, [rax]
		call SDL_OpenGamepad
		mov [gamepad], rax
	gamepadInitEnd:

	; SDL_CreateWindow
	lea rcx, [window_title]
	mov edx, SCREEN_WIDTH
	mov r8d, SCREEN_HEIGHT
	; xor r9d, r9d
	mov r9d, 1 ; fullscreen
	call SDL_CreateWindow
	mov qword ptr [window], rax

	; SDL_CreateRenderer
	mov rcx, rax ; still has &window
	xor rdx, rdx
	call SDL_CreateRenderer
	mov qword ptr [renderer], rax

	setWindowIcon

	; SDL_CreateSurface
	mov rcx, SCREEN_WIDTH
	mov rdx, SCREEN_HEIGHT
	mov r8d, SDL_PIXELFORMAT_RGBA32
	call SDL_CreateSurface
	mov qword ptr [surface], rax

	xor rax, rax
	mov [frame_counter], rax

	mainLoop:
		call SDL_GetTicks
		mov qword ptr [ticks], rax

		xor eax, eax
		btr [keys_down], Keys_Any
		btr [keys_down], Keys_Fire
		btr [keys_down], Keys_Teleport
		pollLoop:
			lea rcx, event
			call SDL_PollEvent
			test al, al
			je pollLoopEnd

			; NEXT:
			; mov eax, [event].SDL_Event.event_type
			; cmp eax, SDL_EVENT_QUIT
			; je quit
			; cmp eax, SDL_EVENT_KEY_DOWN
			; je handleKeyDown
			; cmp eax, SDL_EVENT_KEY_UP
			; je handleKeyUp
			; cmp eax, SDL_EVENT_GAMEPAD_BUTTON_DOWN
			; je handleGamepadButtonDown
			; cmp eax, SDL_EVENT_GAMEPAD_BUTTON_UP
			; je handleGamepadButtonUp
			; cmp eax, SDL_EVENT_GAMEPAD_AXIS_MOTION
			; je handleGamepadAxisMotion

			cmp [event].SDL_Event.event_type, SDL_EVENT_QUIT
			je quit


			cmp [event].SDL_Event.event_type, SDL_EVENT_KEY_DOWN
			jne keyDownCheckEnd
			; which key was pressed?
			mov eax, [event].SDL_KeyboardEvent.key
			cmp eax, SDLK_W
			je BoostPressed
			cmp eax, SDLK_UP
			je BoostPressed
			cmp eax, SDLK_A
			je LeftPressed
			cmp eax, SDLK_LEFT
			je LeftPressed
			cmp eax, SDLK_D
			je RightPressed
			cmp eax, SDLK_RIGHT
			je RightPressed
			cmp eax, SDLK_Q
			je quit
			jmp pollLoopNext
			keyDownCheckEnd:

			cmp [event].SDL_Event.event_type, SDL_EVENT_KEY_UP
			jne keyUpCheckEnd
			bts [keys_down], Keys_Any
			; which key was pressed?
			mov eax, [event].SDL_KeyboardEvent.key
			cmp eax, SDLK_W
			je BoostReleased
			cmp eax, SDLK_UP
			je BoostReleased
			cmp eax, SDLK_A
			je LeftReleased
			cmp eax, SDLK_LEFT
			je LeftReleased
			cmp eax, SDLK_D
			je RightReleased
			cmp eax, SDLK_RIGHT
			je RightReleased
			cmp eax, SDLK_S
			je TeleportPressed
			cmp eax, SDLK_DOWN
			je TeleportPressed
			cmp eax, SDLK_SPACE
			je FirePressed
			cmp eax, SDLK_L
			je FirePressed
			cmp eax, SDLK_ESC
			je pausePressed
			jmp pollLoopNext
			keyUpCheckEnd:

			cmp [event].SDL_Event.event_type, SDL_EVENT_GAMEPAD_BUTTON_DOWN
			jne gamepadButtonDownCheckEnd
			bts [keys_down], Keys_Any
			xor eax, eax
			mov al, [event].SDL_GamepadButtonEvent.button
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_UP
			je BoostPressed
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_LEFT
			je LeftPressed
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_RIGHT
			je RightPressed
			jmp pollLoopNext
			gamepadButtonDownCheckEnd:

			cmp [event].SDL_Event.event_type, SDL_EVENT_GAMEPAD_BUTTON_UP
			jne gamepadButtonUpCheckEnd
			xor eax, eax
			mov al, [event].SDL_GamepadButtonEvent.button
			cmp al, SDL_GAMEPAD_BUTTON_SOUTH
			je FirePressed
			cmp al, SDL_GAMEPAD_BUTTON_EAST
			je FirePressed
			cmp al, SDL_GAMEPAD_BUTTON_WEST
			je TeleportPressed
			cmp al, SDL_GAMEPAD_BUTTON_NORTH
			je TeleportPressed
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_DOWN
			je TeleportPressed
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_UP
			je BoostReleased
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_LEFT
			je LeftReleased
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_RIGHT
			je RightReleased
			cmp al, SDL_GAMEPAD_BUTTON_START
			je pausePressed
			jmp pollLoopNext
			gamepadButtonUpCheckEnd:

			AXIS_TURN_DEADZONE = 4000h
			AXIS_BOOST_DEADZONE = 4000h
			cmp [event].SDL_Event.event_type, SDL_EVENT_GAMEPAD_AXIS_MOTION
			jne gamepadAxisCheckEnd
			xor eax, eax
			mov al, [event].SDL_GamepadAxisEvent.axis
			mov bx, [event].SDL_GamepadAxisEvent.value
			cmp al, SDL_GAMEPAD_AXIS_LEFTY
			jne @f
				cmp bx, -AXIS_BOOST_DEADZONE
				jl BoostPressed
				cmp bx, AXIS_BOOST_DEADZONE
				jl BoostReleased
				jmp pollLoopNext
			@@:
			cmp al, SDL_GAMEPAD_AXIS_LEFTX
			jne @f
				cmp bx, AXIS_TURN_DEADZONE
				jg RightPressed
				cmp bx, -AXIS_TURN_DEADZONE
				jl LeftPressed
				btr [keys_down], Keys_Right ; RightReleased
				jmp LeftReleased
			@@:
			jmp pollLoopNext
			gamepadAxisCheckEnd:


			pollLoopNext:
			jmp pollLoop

			; callbacks
			for key, <Boost, Teleport, Fire, Left, Right>
				@CatStr(key, Pressed):
					bts [keys_down], @CatStr(Keys_, key)
					jmp pollLoopNext
			endm
			for key, <Boost, Left, Right>
				@CatStr(key, Released):
					btr [keys_down], @CatStr(Keys_, key)
					jmp pollLoopNext
			endm
			pausePressed:
				xor [is_paused], 1
		pollLoopEnd:

		call screen_clearPixelBuffer

		call star_updateAndDrawAll

		lea rdi, keys_down
		cmp [mode], Mode_Game
		je doGameTick
			call title_tick
			jmp ticksEnd
		doGameTick:
			call game_tick
		ticksEnd:

		call render

		; 60fps
		call SDL_GetTicks
		sub rax, qword ptr [ticks]
		mov rcx, 1000 / 60
		sub rcx, rax
		js delayEnd ; more than 1/60 of a second has already elapsed, next frame
		call SDL_Delay
		delayEnd:

		inc [frame_counter]
		jmp mainLoop
	
	quit:
	cmp [joystick_ids], 0
	je @f
		mov rcx, [joystick_ids]
		call SDL_free
		mov rcx, [gamepad]
		call SDL_CloseGamepad
	@@:
	mov rcx, [surface]
	call SDL_DestroySurface
	mov rcx, [renderer]
	call SDL_DestroyRenderer
	mov rcx, [window]
	call SDL_DestroyWindow
	mov rcx, [icon]
	call SDL_DestroySurface
	call SDL_Quit

	mov rsp, rbp
	pop rbp
	xor eax, eax
	call ExitProcess
	ret
main endp

render proc
	push rbp
	mov rbp, rsp
	sub rsp, 100h

	mov rcx, [renderer]
	call SDL_RenderClear

	mov rcx, [renderer]
	call SDL_LockSurface

	; memcpy all the pixels over to surface->pixels
	mov rbx, [surface]
	mov rdi, [rbx].SDL_Surface.pixels
	lea rsi, pixels
	mov ecx, (SCREEN_WIDTH * SCREEN_HEIGHT * 4) / 32
	; brk
	call memcpyAligned32

	mov rcx, [renderer]
	call SDL_UnlockSurface

	mov rcx, [renderer]
	mov rdx, [surface]
	call SDL_CreateTextureFromSurface
	mov qword ptr [texture], rax

	mov rcx, rax
	mov edx, SDL_SCALEMODE_NEAREST
	call SDL_SetTextureScaleMode

	mov rcx, [renderer]
	mov rdx, [texture]
	xor r8d, r8d
	xor r9d, r9d
	call SDL_RenderTexture

	mov rcx, [renderer]
	call SDL_RenderPresent

	mov rcx, [texture]
	call SDL_DestroyTexture

	mov rsp, rbp
	pop rbp
	ret
render endp


end
