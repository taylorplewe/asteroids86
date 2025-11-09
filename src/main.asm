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
icon_path    db "art/asteroid_512.bmp", 0


section .bss

; SDL stuff
window   resq 1
renderer resq 1
surface  resq 1
texture  resq 1
icon     resq 1
event    resb 2048

ticks     resq 1
input     resb Input_size
keys_prev resd 1;Keys  ?
is_paused resd 1

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

		mov dword [input + Input.buttons_down], 0
		xor eax, eax
		.pollLoop:
			lea rcx, event
			call SDL_PollEvent
			test al, al
			je .pollLoopEnd

			cmp dword [event + SDL_Event.event_type], SDL_EVENT_QUIT
			je .quit

			cmp dword [event + SDL_Event.event_type], SDL_EVENT_KEY_DOWN
			jne ._7
			bts dword [input + Input.buttons_down], Keys_Other
			cmp dword [event + SDL_KeyboardEvent.key], SDLK_Q
			je .quit
			jmp .pollLoopNext
			._7:

			cmp dword [event + SDL_Event.event_type], SDL_EVENT_GAMEPAD_BUTTON_DOWN
			jne .gamepadButtonDownCheckEnd
			bts dword [input + Input.buttons_down], Keys_Other
			.gamepadButtonDownCheckEnd:

			.pollLoopNext:
			jmp .pollLoop
		.pollLoopEnd:

		; get input
		mov word [input + Input.boost_val], 7fffh
		cmp qword [gamepad], 0
		jne .getGamepadInput
		;getKeyboardInput:
			call SDL_GetKeyboardState
			mov rbx, rax
			; BTN_W      textequ <Boost>
			; BTN_A      textequ <Left>
			; BTN_S      textequ <Teleport>
			; BTN_D      textequ <Right>
			; BTN_L      textequ <Fire>
			; BTN_ESCAPE textequ <Pause>
			; BTN_SPACE  textequ <Fire>
			; BTN_UP     textequ <Boost>
			; BTN_DOWN   textequ <Teleport>
			; BTN_LEFT   textequ <Left>
			; BTN_RIGHT  textequ <Right>
			; for key, <A, D, L, S, W, ESCAPE, SPACE, UP, DOWN, LEFT, RIGHT>
			; 	local press
			; 	local next
			; 	mov al, @CatStr(SDL_SCANCODE_, key)
			; 	xlatb
			; 	test al, al
			; 	je next
			; 	bts dword [input + Input.buttons_down], @CatStr(Keys_, %@CatStr(BTN_, key))
			; 	next:
			; endm

			mov al, SDL_SCANCODE_A
			xlatb
			test al, al
			je .keyTestNext0
			bts dword [input + Input.buttons_down], Keys_Left
			.keyTestNext0:
			
			mov al, SDL_SCANCODE_D
			xlatb
			test al, al
			je .keyTestNext1
			bts dword [input + Input.buttons_down], Keys_Right
			.keyTestNext1:
			
			mov al, SDL_SCANCODE_L
			xlatb
			test al, al
			je .keyTestNext2
			bts dword [input + Input.buttons_down], Keys_Fire
			.keyTestNext2:
			
			mov al, SDL_SCANCODE_S
			xlatb
			test al, al
			je .keyTestNext3
			bts dword [input + Input.buttons_down], Keys_Teleport
			.keyTestNext3:
			
			mov al, SDL_SCANCODE_W
			xlatb
			test al, al
			je .keyTestNext4
			bts dword [input + Input.buttons_down], Keys_Boost
			.keyTestNext4:
			
			mov al, SDL_SCANCODE_ESCAPE
			xlatb
			test al, al
			je .keyTestNext5
			bts dword [input + Input.buttons_down], Keys_Pause
			.keyTestNext5:
			
			mov al, SDL_SCANCODE_SPACE
			xlatb
			test al, al
			je .keyTestNext6
			bts dword [input + Input.buttons_down], Keys_Fire
			.keyTestNext6:
			
			mov al, SDL_SCANCODE_UP
			xlatb
			test al, al
			je .keyTestNext7
			bts dword [input + Input.buttons_down], Keys_Boost
			.keyTestNext7:
			
			mov al, SDL_SCANCODE_DOWN
			xlatb
			test al, al
			je .keyTestNext8
			bts dword [input + Input.buttons_down], Keys_Teleport
			.keyTestNext8:
			
			mov al, SDL_SCANCODE_LEFT
			xlatb
			test al, al
			je .keyTestNext9
			bts dword [input + Input.buttons_down], Keys_Left
			.keyTestNext9:
			
			mov al, SDL_SCANCODE_RIGHT
			xlatb
			test al, al
			je .keyTestNext10
			bts dword [input + Input.buttons_down], Keys_Right
			.keyTestNext10:
			
			jmp .inputEnd
		.getGamepadInput:

			; BTN_DPAD_UP    textequ <Boost>
			; BTN_DPAD_DOWN  textequ <Teleport>
			; BTN_DPAD_LEFT  textequ <Left>
			; BTN_DPAD_RIGHT textequ <Right>
			; BTN_SOUTH      textequ <Fire>
			; BTN_EAST       textequ <Fire>
			; BTN_WEST       textequ <Teleport>
			; BTN_NORTH      textequ <Teleport>
			; BTN_START      textequ <Pause>
			; for btn, <DPAD_UP, DPAD_DOWN, DPAD_LEFT, DPAD_RIGHT, SOUTH, EAST, WEST, NORTH, START>
			; 	local next

			; 	mov [input + Input.boost_val], 7fffh
			; 	mov rcx, [gamepad]
			; 	mov edx, @CatStr(SDL_GAMEPAD_BUTTON_, btn)
			; 	call SDL_GetGamepadButton
			; 	test al, al
			; 	je next
			; 	bts [input + Input.buttons_down], @CatStr(Keys_, %@CatStr(BTN_, btn))
			
			; 	next:
			; endm

			mov rcx, [gamepad]
			mov edx, SDL_GAMEPAD_BUTTON_DPAD_UP
			call SDL_GetGamepadButton
			test al, al
			je .gamepadTestNext0
			bts [input + Input.buttons_down], Keys_Boost
			.gamepadTestNext0:
			
			mov rcx, [gamepad]
			mov edx, SDL_GAMEPAD_BUTTON_DPAD_DOWN
			call SDL_GetGamepadButton
			test al, al
			je .gamepadTestNext1
			bts [input + Input.buttons_down], Keys_Teleport
			.gamepadTestNext1:
			
			mov rcx, [gamepad]
			mov edx, SDL_GAMEPAD_BUTTON_DPAD_LEFT
			call SDL_GetGamepadButton
			test al, al
			je .gamepadTestNext2
			bts [input + Input.buttons_down], Keys_Left
			.gamepadTestNext2:
			
			mov rcx, [gamepad]
			mov edx, SDL_GAMEPAD_BUTTON_DPAD_RIGHT
			call SDL_GetGamepadButton
			test al, al
			je .gamepadTestNext3
			bts [input + Input.buttons_down], Keys_Right
			.gamepadTestNext3:
			
			mov rcx, [gamepad]
			mov edx, SDL_GAMEPAD_BUTTON_SOUTH
			call SDL_GetGamepadButton
			test al, al
			je .gamepadTestNext4
			bts [input + Input.buttons_down], Keys_Fire
			.gamepadTestNext4:
			
			mov rcx, [gamepad]
			mov edx, SDL_GAMEPAD_BUTTON_EAST
			call SDL_GetGamepadButton
			test al, al
			je .gamepadTestNext5
			bts [input + Input.buttons_down], Keys_Fire
			.gamepadTestNext5:
			
			mov rcx, [gamepad]
			mov edx, SDL_GAMEPAD_BUTTON_WEST
			call SDL_GetGamepadButton
			test al, al
			je .gamepadTestNext6
			bts [input + Input.buttons_down], Keys_Teleport
			.gamepadTestNext6:
			
			mov rcx, [gamepad]
			mov edx, SDL_GAMEPAD_BUTTON_NORTH
			call SDL_GetGamepadButton
			test al, al
			je .gamepadTestNext7
			bts [input + Input.buttons_down], Keys_Teleport
			.gamepadTestNext7:
			
			mov rcx, [gamepad]
			mov edx, SDL_GAMEPAD_BUTTON_START
			call SDL_GetGamepadButton
			test al, al
			je .gamepadTestNext8
			bts [input + Input.buttons_down], Keys_Pause
			.gamepadTestNext8:
			
			
			; axis
			AXIS_TURN_DEADZONE  equ 4000h
			AXIS_BOOST_DEADZONE equ 500h

			mov rcx, [gamepad]
			mov edx, SDL_GAMEPAD_AXIS_LEFTX
			call SDL_GetGamepadAxis
			cmp ax, AXIS_TURN_DEADZONE
			jle ._8
				bts dword [input + Input.buttons_down], Keys_Right
				jmp .leftXCheckEnd
			._8:
			cmp ax, (-AXIS_TURN_DEADZONE) & 0ffffh
			jge ._9
				bts dword [input + Input.buttons_down], Keys_Left
			._9:
			.leftXCheckEnd:

			mov rcx, [gamepad]
			mov edx, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER
			call SDL_GetGamepadAxis
			cmp ax, AXIS_BOOST_DEADZONE
			jle ._10
			mov [input + Input.boost_val], ax
			bts dword [input + Input.buttons_down], Keys_Boost
			._10:
		.inputEnd:

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
		jnc ._11
			xor dword [is_paused], 1
		._11:

		mov dword [event_bus], 0

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
			mov dx, 8000h
			mov r8w, 0
			mov r9d, 50
			call SDL_RumbleGamepad
		._4:
		bt dword [event_bus], Event_ShipDestroy
		jnc ._5
			mov rcx, [gamepad]
			mov dx, 3fffh
			mov r8w, 0afffh
			mov r9d, 700
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
	mov rax, [rbx + SDL_Surface.pixels]
	screen_setPixelPtr
	; mov rsi, [pixels]
	; mov ecx, (SCREEN_WIDTH * SCREEN_HEIGHT * 4) / 8
	; memcpyAligned32

	call screen_clearPixelBuffer

	call star_drawAll

	cmp [mode], Mode_Game
	je doGameDraw
		call title_draw
		jmp drawsEnd
	doGameDraw:
		call game_draw
	drawsEnd:

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