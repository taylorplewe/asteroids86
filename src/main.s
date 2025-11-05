%use masm


%include "src/globaldefs.inc"
%include "src/sdl/defs.inc"

%include "src/data/flicker-alphas.inc"
%include "src/common.s"
%include "src/screen.s"
%include "src/font.s"

%include "src/game.s"
%include "src/title.s"


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

ticks     dq    ?
input     Input <>
keys_prev Keys  ?
is_paused dd    ?

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
			cmp eax, SDLK_S
			je TeleportPressed
			cmp eax, SDLK_DOWN
			je TeleportPressed
			cmp eax, SDLK_A
			je LeftPressed
			cmp eax, SDLK_LEFT
			je LeftPressed
			cmp eax, SDLK_D
			je RightPressed
			cmp eax, SDLK_RIGHT
			je RightPressed
			cmp eax, SDLK_SPACE
			je FirePressed
			cmp eax, SDLK_L
			je FirePressed
			cmp eax, SDLK_Q
			je quit
			cmp eax, SDLK_ESC
			je PausePressed
			jmp OtherPressed
			keyDownCheckEnd:

			cmp [event].SDL_Event.event_type, SDL_EVENT_KEY_UP
			jne keyUpCheckEnd
			mov eax, [event].SDL_KeyboardEvent.key
			cmp eax, SDLK_W
			je BoostReleased
			cmp eax, SDLK_UP
			je BoostReleased
			cmp eax, SDLK_S
			je TeleportReleased
			cmp eax, SDLK_DOWN
			je TeleportReleased
			cmp eax, SDLK_A
			je LeftReleased
			cmp eax, SDLK_LEFT
			je LeftReleased
			cmp eax, SDLK_D
			je RightReleased
			cmp eax, SDLK_RIGHT
			je RightReleased
			cmp eax, SDLK_SPACE
			je FireReleased
			cmp eax, SDLK_L
			je FireReleased
			cmp eax, SDLK_ESC
			je PauseReleased
			jmp OtherReleased
			keyUpCheckEnd:

			cmp [event].SDL_Event.event_type, SDL_EVENT_GAMEPAD_BUTTON_DOWN
			jne gamepadButtonDownCheckEnd
			xor eax, eax
			mov al, [event].SDL_GamepadButtonEvent.button
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_UP
			je BoostPressed
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_DOWN
			je TeleportPressed
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_LEFT
			je LeftPressed
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_RIGHT
			je RightPressed
			cmp al, SDL_GAMEPAD_BUTTON_SOUTH
			je FirePressed
			cmp al, SDL_GAMEPAD_BUTTON_EAST
			je FirePressed
			cmp al, SDL_GAMEPAD_BUTTON_WEST
			je TeleportPressed
			cmp al, SDL_GAMEPAD_BUTTON_NORTH
			je TeleportPressed
			cmp al, SDL_GAMEPAD_BUTTON_START
			je PausePressed
			jmp OtherPressed
			gamepadButtonDownCheckEnd:

			cmp [event].SDL_Event.event_type, SDL_EVENT_GAMEPAD_BUTTON_UP
			jne gamepadButtonUpCheckEnd
			xor eax, eax
			mov al, [event].SDL_GamepadButtonEvent.button
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_UP
			je BoostReleased
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_DOWN
			je TeleportReleased
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_LEFT
			je LeftReleased
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_RIGHT
			je RightReleased
			cmp al, SDL_GAMEPAD_BUTTON_SOUTH
			je FireReleased
			cmp al, SDL_GAMEPAD_BUTTON_EAST
			je FireReleased
			cmp al, SDL_GAMEPAD_BUTTON_WEST
			je TeleportReleased
			cmp al, SDL_GAMEPAD_BUTTON_NORTH
			je TeleportReleased
			cmp al, SDL_GAMEPAD_BUTTON_START
			je PauseReleased
			jmp OtherReleased
			gamepadButtonUpCheckEnd:

			AXIS_TURN_DEADZONE = 4000h
			AXIS_BOOST_DEADZONE = 4000h
			AXIS_FIRE_DEADZONE = 3000h
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
				btr [input].buttons_down, Keys_Right ; RightReleased
				jmp LeftReleased
			@@:
			cmp al, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER
			jne @f
				cmp bx, AXIS_FIRE_DEADZONE
				jg BoostPressed
				; brk
				jmp BoostReleased
			@@:
			jmp pollLoopNext
			gamepadAxisCheckEnd:


			pollLoopNext:
			jmp pollLoop

			; callbacks
			for key, <Boost, Teleport, Left, Right, Fire, Pause, Other>
				@CatStr(key, Pressed):
					bts [input].buttons_down, @CatStr(Keys_, key)
					jmp pollLoopNext
			endm
			for key, <Boost, Teleport, Left, Right, Fire, Pause, Other>
				@CatStr(key, Released):
					btr [input].buttons_down, @CatStr(Keys_, key)
					jmp pollLoopNext
			endm
		pollLoopEnd:

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

		call screen_clearPixelBuffer

		call star_updateAndDrawAll

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
			mov rcx, [gamepad]
			mov dx, 0afffh
			mov r8w, 00000h
			mov r9d, 50
			call SDL_RumbleGamepad
		@@:
		bt [event_bus], Event_ShipDestroy
		jnc @f
			mov rcx, [gamepad]
			mov dx, 03fffh
			mov r8w, 0afffh
			mov r9d, 1000
			call SDL_RumbleGamepad
		@@:

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
