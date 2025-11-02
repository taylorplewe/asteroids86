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


.code

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

	mov ecx, SDL_INIT_VIDEO
	call SDL_Init

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

			cmp [event].SDL_Event.event_type, SDL_EVENT_QUIT
			je quit

			cmp [event].SDL_Event.event_type, SDL_EVENT_KEY_DOWN
			jne keyDownCheckEnd
			; which key was pressed?
			mov eax, [event].SDL_KeyboardEvent.key
			cmp eax, SDLK_W
			je boostPressed
			cmp eax, SDLK_UP
			jne @f
				boostPressed:
				bts [keys_down], Keys_Boost
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_A
			je leftPressed
			cmp eax, SDLK_LEFT
			jne @f
				leftPressed:
				bts [keys_down], Keys_Left
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_D
			je rightPressed
			cmp eax, SDLK_RIGHT
			jne @f
				rightPressed:
				bts [keys_down], Keys_Right
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_Q
			je quit
			keyDownCheckEnd:

			cmp [event].SDL_Event.event_type, SDL_EVENT_KEY_UP
			jne keyUpCheckEnd
			bts [keys_down], Keys_Any
			; which key was pressed?
			mov eax, [event].SDL_KeyboardEvent.key
			cmp eax, SDLK_W
			je boostReleased
			cmp eax, SDLK_UP
			jne @f
				boostReleased:
				btr [keys_down], Keys_Boost
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_A
			je leftReleased
			cmp eax, SDLK_LEFT
			jne @f
				leftReleased:
				btr [keys_down], Keys_Left
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_D
			je rightReleased
			cmp eax, SDLK_RIGHT
			jne @f
				rightReleased:
				btr [keys_down], Keys_Right
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_S
			je teleportPressed
			cmp eax, SDLK_DOWN
			jne @f
				teleportPressed:
				bts [keys_down], Keys_Teleport
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_SPACE
			je firePressed
			cmp eax, SDLK_L
			jne @f
				firePressed:
				bts [keys_down], Keys_Fire
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_ESC
			jne @f
				xor [is_paused], 1
				; jmp pollLoopNext
			@@:
			keyUpCheckEnd:


			pollLoopNext:
			jmp pollLoop
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


end
