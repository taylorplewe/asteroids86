%use masm


%include "src/globaldefs.inc"
%include "src/sdl/defs.inc"

%include "src/data/flicker-alphas.inc"
%include "src/common.asm"
%include "src/screen.asm"
%include "src/font.asm"

%include "src/game.asm"
%include "src/title.asm"


section .data

window_title db "asteroids86", 0
icon_path    db "art\asteroid_512.bmp", 0


section .bss

; SDL stuff
window   resq 1
renderer resq 1
surface  resq 1
texture  resq 1
icon     resq 1
event    resb 2048

ticks     resq    1
input     resb Input_size
keys_prev resd 1 ;Keys
is_paused resd    1

joystick_ids resq 1
gamepad      resq 1


section .text

%macro setWindowIcon 0
	lea rcx, icon_path
	call SDL_LoadBMP
	; rax = *SDL_Surface

	mov [icon], rax

	mov rdx, rax
	mov rcx, [window]
	call SDL_SetWindowIcon
%endmacro

global main
main:
	push rbp
	mov rbp, rsp
	sub rsp, 200h

	call star_generateAll

	call game_setShipLivesPoints
	call title_init
	mov [mode], Mode_Title

	mov ecx, SDL_INIT_VIDEO | SDL_INIT_GAMEPAD
	call SDL_Init

	; SDL_GetGamepads
	xor ecx, ecx
	call SDL_GetGamepads
	cmp dword [rax], 0
	je .gamepadInitEnd
		mov [joystick_ids], rax
		mov ecx, [rax]
		call SDL_OpenGamepad
		mov [gamepad], rax
	.gamepadInitEnd:

	; SDL_CreateWindow
	lea rcx, [window_title]
	mov edx, SCREEN_WIDTH
	mov r8d, SCREEN_HEIGHT
	; xor r9d, r9d
	mov r9d, 1 ; fullscreen
	call SDL_CreateWindow
	mov qword [window], rax

	; SDL_CreateRenderer
	mov rcx, rax ; still has &window
	xor rdx, rdx
	call SDL_CreateRenderer
	mov qword [renderer], rax

	setWindowIcon

	; SDL_CreateSurface
	mov rcx, SCREEN_WIDTH
	mov rdx, SCREEN_HEIGHT
	mov r8d, SDL_PIXELFORMAT_RGBA32
	call SDL_CreateSurface
	mov qword [surface], rax

	xor rax, rax
	mov [frame_counter], rax

	.mainLoop:
		call SDL_GetTicks
		mov qword [ticks], rax

		xor eax, eax
		.pollLoop:
			lea rcx, event
			call SDL_PollEvent
			test al, al
			je .pollLoopEnd

			; NEXT:
			; mov eax, [event + SDL_Event.event_type]
			; cmp eax, SDL_EVENT_QUIT
			; je .quit
			; cmp eax, SDL_EVENT_KEY_DOWN
			; je .handleKeyDown
			; cmp eax, SDL_EVENT_KEY_UP
			; je .handleKeyUp
			; cmp eax, SDL_EVENT_GAMEPAD_BUTTON_DOWN
			; je .handleGamepadButtonDown
			; cmp eax, SDL_EVENT_GAMEPAD_BUTTON_UP
			; je .handleGamepadButtonUp
			; cmp eax, SDL_EVENT_GAMEPAD_AXIS_MOTION
			; je .handleGamepadAxisMotion

			cmp dword [event + SDL_Event.event_type], SDL_EVENT_QUIT
			je .quit


			cmp dword [event + SDL_Event.event_type], SDL_EVENT_KEY_DOWN
			jne .keyDownCheckEnd
			; which key was pressed?
			mov eax, [event + SDL_KeyboardEvent.key]
			cmp eax, SDLK_W
			je .BoostPressed
			cmp eax, SDLK_UP
			je .BoostPressed
			cmp eax, SDLK_S
			je .TeleportPressed
			cmp eax, SDLK_DOWN
			je .TeleportPressed
			cmp eax, SDLK_A
			je .LeftPressed
			cmp eax, SDLK_LEFT
			je .LeftPressed
			cmp eax, SDLK_D
			je .RightPressed
			cmp eax, SDLK_RIGHT
			je .RightPressed
			cmp eax, SDLK_SPACE
			je .FirePressed
			cmp eax, SDLK_L
			je .FirePressed
			cmp eax, SDLK_Q
			je .quit
			cmp eax, SDLK_ESC
			je .PausePressed
			jmp .OtherPressed
			.keyDownCheckEnd:

			cmp dword [event + SDL_Event.event_type], SDL_EVENT_KEY_UP
			jne .keyUpCheckEnd
			mov eax, [event + SDL_KeyboardEvent.key]
			cmp eax, SDLK_W
			je .BoostReleased
			cmp eax, SDLK_UP
			je .BoostReleased
			cmp eax, SDLK_S
			je .TeleportReleased
			cmp eax, SDLK_DOWN
			je .TeleportReleased
			cmp eax, SDLK_A
			je .LeftReleased
			cmp eax, SDLK_LEFT
			je .LeftReleased
			cmp eax, SDLK_D
			je .RightReleased
			cmp eax, SDLK_RIGHT
			je .RightReleased
			cmp eax, SDLK_SPACE
			je .FireReleased
			cmp eax, SDLK_L
			je .FireReleased
			cmp eax, SDLK_ESC
			je .PauseReleased
			jmp .OtherReleased
			.keyUpCheckEnd:

			cmp dword [event + SDL_Event.event_type], SDL_EVENT_GAMEPAD_BUTTON_DOWN
			jne .gamepadButtonDownCheckEnd
			xor eax, eax
			mov al, [event + SDL_GamepadButtonEvent.button]
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_UP
			je .BoostPressed
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_DOWN
			je .TeleportPressed
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_LEFT
			je .LeftPressed
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_RIGHT
			je .RightPressed
			cmp al, SDL_GAMEPAD_BUTTON_SOUTH
			je .FirePressed
			cmp al, SDL_GAMEPAD_BUTTON_EAST
			je .FirePressed
			cmp al, SDL_GAMEPAD_BUTTON_WEST
			je .TeleportPressed
			cmp al, SDL_GAMEPAD_BUTTON_NORTH
			je .TeleportPressed
			cmp al, SDL_GAMEPAD_BUTTON_START
			je .PausePressed
			jmp .OtherPressed
			.gamepadButtonDownCheckEnd:

			cmp dword [event + SDL_Event.event_type], SDL_EVENT_GAMEPAD_BUTTON_UP
			jne .gamepadButtonUpCheckEnd
			xor eax, eax
			mov al, [event + SDL_GamepadButtonEvent.button]
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_UP
			je .BoostReleased
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_DOWN
			je .TeleportReleased
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_LEFT
			je .LeftReleased
			cmp al, SDL_GAMEPAD_BUTTON_DPAD_RIGHT
			je .RightReleased
			cmp al, SDL_GAMEPAD_BUTTON_SOUTH
			je .FireReleased
			cmp al, SDL_GAMEPAD_BUTTON_EAST
			je .FireReleased
			cmp al, SDL_GAMEPAD_BUTTON_WEST
			je .TeleportReleased
			cmp al, SDL_GAMEPAD_BUTTON_NORTH
			je .TeleportReleased
			cmp al, SDL_GAMEPAD_BUTTON_START
			je .PauseReleased
			jmp .OtherReleased
			.gamepadButtonUpCheckEnd:

			AXIS_TURN_DEADZONE equ 4000h
			AXIS_BOOST_DEADZONE equ 4000h
			AXIS_FIRE_DEADZONE equ 3000h
			cmp dword [event + SDL_Event.event_type], SDL_EVENT_GAMEPAD_AXIS_MOTION
			jne .gamepadAxisCheckEnd
			xor eax, eax
			mov al, [event + SDL_GamepadAxisEvent.axis]
			mov bx, [event + SDL_GamepadAxisEvent.value]
			cmp al, SDL_GAMEPAD_AXIS_LEFTY
			jne ._
				cmp bx, -AXIS_BOOST_DEADZONE
				jl .BoostPressed
				cmp bx, AXIS_BOOST_DEADZONE
				jl .BoostReleased
				jmp .pollLoopNext
			._:
			cmp al, SDL_GAMEPAD_AXIS_LEFTX
			jne ._1
				cmp bx, AXIS_TURN_DEADZONE
				jg .RightPressed
				cmp bx, -AXIS_TURN_DEADZONE
				jl .LeftPressed
				btr [input + Input.buttons_down], Keys_Right ; RightReleased
				jmp .LeftReleased
			._1:
			cmp al, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER
			jne ._2
				cmp bx, AXIS_FIRE_DEADZONE
				jg .BoostPressed
				; brk
				jmp .BoostReleased
			._2:
			jmp .pollLoopNext
			.gamepadAxisCheckEnd:


			.pollLoopNext:
			jmp .pollLoop

			; callbacks
			; for key, <Boost, Teleport, Left, Right, Fire, Pause, Other>
			; 	@CatStr(key, Pressed):
			; 		bts [input + Input.buttons_down], @CatStr(Keys_, key)
			; 		jmp .pollLoopNext
			; endm
			; for key, <Boost, Teleport, Left, Right, Fire, Pause, Other>
			; 	@CatStr(key, Released):
			; 		btr [input + Input.buttons_down], @CatStr(Keys_, key)
			; 		jmp .pollLoopNext
			; endm

			.BoostPressed:
				bts dword [input + Input.buttons_down], Keys_Boost
				jmp .pollLoopNext
			.TeleportPressed:
				bts dword [input + Input.buttons_down], Keys_Teleport
				jmp .pollLoopNext
			.LeftPressed:
				bts dword [input + Input.buttons_down], Keys_Left
				jmp .pollLoopNext
			.RightPressed:
				bts dword [input + Input.buttons_down], Keys_Right
				jmp .pollLoopNext
			.FirePressed:
				bts dword [input + Input.buttons_down], Keys_Fire
				jmp .pollLoopNext
			.PausePressed:
				bts dword [input + Input.buttons_down], Keys_Pause
				jmp .pollLoopNext
			.OtherPressed:
				bts dword [input + Input.buttons_down], Keys_Other
				jmp .pollLoopNext

			.BoostReleased:
				btr dword [input + Input.buttons_down], Keys_Boost
				jmp .pollLoopNext
			.TeleportReleased:
				btr dword [input + Input.buttons_down], Keys_Teleport
				jmp .pollLoopNext
			.LeftReleased:
				btr dword [input + Input.buttons_down], Keys_Left
				jmp .pollLoopNext
			.RightReleased:
				btr dword [input + Input.buttons_down], Keys_Right
				jmp .pollLoopNext
			.FireReleased:
				btr dword [input + Input.buttons_down], Keys_Fire
				jmp .pollLoopNext
			.PauseReleased:
				btr dword [input + Input.buttons_down], Keys_Pause
				jmp .pollLoopNext
			.OtherReleased:
				btr dword [input + Input.buttons_down], Keys_Other
				jmp .pollLoopNext

		.pollLoopEnd:

		; set pressed & released keys
		; pressed = (down ^ prev) & down
		; released = (down ^ prev) & prev
		mov eax, [input + Input.buttons_down]
		mov ebx, [keys_prev]
		xor ebx, eax
		mov ecx, ebx
		and ecx, [keys_prev]
		mov [input + Input.buttons_released], ecx
		and ebx, [input + Input.buttons_down]
		mov [input + Input.buttons_pressed], ebx
		mov [keys_prev], eax

		bt dword [input + Input.buttons_pressed], Keys_Pause
		jnc ._3
			xor dword [is_paused], 1
		._3:

		mov dword [event_bus], 0

		call screen_clearPixelBuffer

		call star_updateAndDrawAll

		lea rdi, input
		cmp dword [mode], Mode_Game
		je .doGameTick
			call title_tick
			jmp .ticksEnd
		.doGameTick:
			call game_tick
		.ticksEnd:

		; rumble gamepad for events that happened this frame
		bt dword [event_bus], Event_Fire
		jnc ._4
			mov rcx, [gamepad]
			mov dx, 0afffh
			mov r8w, 00000h
			mov r9d, 50
			call SDL_RumbleGamepad
		._4:
		bt dword [event_bus], Event_ShipDestroy
		jnc ._5
			mov rcx, [gamepad]
			mov dx, 03fffh
			mov r8w, 0afffh
			mov r9d, 1000
			call SDL_RumbleGamepad
		._5:

		call render

		; 60fps
		call SDL_GetTicks
		sub rax, qword [ticks]
		mov rcx, 1000 / 60
		sub rcx, rax
		js .delayEnd ; more than 1/60 of a second has already elapsed, next frame
		call SDL_Delay
		.delayEnd:

		inc [frame_counter]
		jmp .mainLoop
	
	.quit:
	cmp [joystick_ids], 0
	je ._6
		mov rcx, [joystick_ids]
		call SDL_free
		mov rcx, [gamepad]
		call SDL_CloseGamepad
	._6:
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
	ret


render:
	push rbp
	mov rbp, rsp
	sub rsp, 100h

	mov rcx, [renderer]
	call SDL_RenderClear

	mov rcx, [renderer]
	call SDL_LockSurface

	; memcpy all the pixels over to surface->pixels
	mov rbx, [surface]
	mov rdi, [rbx + SDL_Surface.pixels]
	lea rsi, pixels
	mov ecx, (SCREEN_WIDTH * SCREEN_HEIGHT * 4) / 32
	call memcpyAligned32

	mov rcx, [renderer]
	call SDL_UnlockSurface

	mov rcx, [renderer]
	mov rdx, [surface]
	call SDL_CreateTextureFromSurface
	mov qword [texture], rax

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



end
