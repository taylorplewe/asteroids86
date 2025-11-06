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

ticks     dq    ?
input     Input <>
keys_prev Keys  ?
is_paused dd    ?

; input
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

		mov [input].buttons_down, 0
		xor eax, eax
		pollLoop:
			lea rcx, event
			call SDL_PollEvent
			test al, al
			je pollLoopEnd

			cmp [event].SDL_Event.event_type, SDL_EVENT_QUIT
			je quit

			cmp [event].SDL_Event.event_type, SDL_EVENT_KEY_DOWN
			jne @f
			bts [input].buttons_down, Keys_Other
			cmp [event].SDL_KeyboardEvent.key, SDLK_Q
			je quit
			jmp pollLoopNext
			@@:

			cmp [event].SDL_Event.event_type, SDL_EVENT_GAMEPAD_BUTTON_DOWN
			jne gamepadButtonDownCheckEnd
			bts [input].buttons_down, Keys_Other
			gamepadButtonDownCheckEnd:

			pollLoopNext:
			jmp pollLoop
		pollLoopEnd:

		; get input
		cmp [gamepad], 0
		jne getGamepadInput
		;getKeyboardInput:
			call SDL_GetKeyboardState
			mov rbx, rax
			BTN_W      textequ <Boost>
			BTN_A      textequ <Left>
			BTN_S      textequ <Teleport>
			BTN_D      textequ <Right>
			BTN_L      textequ <Fire>
			BTN_ESCAPE textequ <Pause>
			BTN_SPACE  textequ <Fire>
			BTN_UP     textequ <Boost>
			BTN_DOWN   textequ <Teleport>
			BTN_LEFT   textequ <Left>
			BTN_RIGHT  textequ <Right>
			for key, <A, D, L, S, W, ESCAPE, SPACE, UP, DOWN, LEFT, RIGHT>
				local press
				local next
				mov al, @CatStr(SDL_SCANCODE_, key)
				xlatb
				test al, al
				je next
				bts [input].buttons_down, @CatStr(Keys_, %@CatStr(BTN_, key))
				next:
			endm

			mov [input].boost_val, 7fffh
			jmp inputEnd
		getGamepadInput:

			BTN_DPAD_UP    textequ <Boost>
			BTN_DPAD_DOWN  textequ <Teleport>
			BTN_DPAD_LEFT  textequ <Left>
			BTN_DPAD_RIGHT textequ <Right>
			BTN_SOUTH      textequ <Fire>
			BTN_EAST       textequ <Fire>
			BTN_WEST       textequ <Teleport>
			BTN_NORTH      textequ <Teleport>
			BTN_START      textequ <Pause>
			for btn, <DPAD_UP, DPAD_DOWN, DPAD_LEFT, DPAD_RIGHT, SOUTH, EAST, WEST, NORTH, START>
				local next

				mov [input].boost_val, 7fffh
				mov rcx, [gamepad]
				mov edx, @CatStr(SDL_GAMEPAD_BUTTON_, btn)
				call SDL_GetGamepadButton
				test al, al
				je next
				bts [input].buttons_down, @CatStr(Keys_, %@CatStr(BTN_, btn))
			
				next:
			endm

			; axis
			AXIS_TURN_DEADZONE = 4000h
			AXIS_BOOST_DEADZONE = 500h

			mov rcx, [gamepad]
			mov edx, SDL_GAMEPAD_AXIS_LEFTX
			call SDL_GetGamepadAxis
			cmp ax, AXIS_TURN_DEADZONE
			jle @f
				bts [input].buttons_down, Keys_Right
				jmp leftXCheckEnd
			@@:
			cmp ax, -AXIS_TURN_DEADZONE
			jge @f
				bts [input].buttons_down, Keys_Left
			@@:
			leftXCheckEnd:

			mov rcx, [gamepad]
			mov edx, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER
			call SDL_GetGamepadAxis
			cmp ax, AXIS_BOOST_DEADZONE
			jle @f
			mov [input].boost_val, ax
			bts [input].buttons_down, Keys_Boost
			@@:
		inputEnd:

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
			mov dx, 8000h
			mov r8w, 0
			mov r9d, 50
			call SDL_RumbleGamepad
		@@:
		bt [event_bus], Event_ShipDestroy
		jnc @f
			mov rcx, [gamepad]
			mov dx, 3fffh
			mov r8w, 0afffh
			mov r9d, 700
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
	mov ecx, (SCREEN_WIDTH * SCREEN_HEIGHT * 4) / 8
	memcpyAligned32

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
