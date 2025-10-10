include <globaldefs.inc>
include <sdl\defs.inc>

include <ship.s>
include <screen.s>
include <asteroids.s>


.data

window_title byte "ASTEROIDS 86", 0

; SDL stuff
window   qword ?
renderer qword ?
surface  qword ?
texture  qword ?
event    byte 2048 dup (?)

ticks qword ?
keys_down Keys <?>


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
	mov ebx, (SCREEN_WIDTH * SCREEN_HEIGHT)/2
	call memcpyAligned64

	mov rcx, [renderer]
	call SDL_UnlockSurface

	mov rcx, [renderer]
	mov rdx, [surface]
	call SDL_CreateTextureFromSurface
	mov qword ptr [texture], rax

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

; TODO: make use of MOVDIR64B instruction? x86 has like fifty different MOV variant instructions lmao
; in:
	; rdi = destination ptr
	; rsi = source ptr
	; ebx = count of qwords
memcpyAligned64 proc
	mainLoop:
		mov rax, qword ptr [rsi]
		mov qword ptr [rdi], rax
		add rsi, 8
		add rdi, 8
		dec ebx
		jne mainLoop
	ret
memcpyAligned64 endp

clearPixelBuffer proc
	mov ebx, (SCREEN_WIDTH*SCREEN_HEIGHT)/2
	lea rdi, [pixels]
	mov rax, 0
	mainLoop:
		mov qword ptr [rdi], rax
		add rdi, 8
		dec ebx
		jne mainLoop
		
	ret
clearPixelBuffer endp

main proc
	push rbp
	mov rbp, rsp
	sub rsp, 200h

	call ship_init

	mov ecx, SDL_INIT_VIDEO
	call SDL_Init

	; SDL_CreateWindow
	lea rcx, [window_title]
	mov edx, SCREEN_WIDTH
	mov r8d, SCREEN_HEIGHT
	xor r9d, r9d
	call SDL_CreateWindow
	mov qword ptr [window], rax

	; SDL_CreateRenderer
	mov rcx, rax ; still has &window
	xor rdx, rdx
	call SDL_CreateRenderer
	mov qword ptr [renderer], rax

	; SDL_CreateSurface
	mov rcx, SCREEN_WIDTH
	mov rdx, SCREEN_HEIGHT
	mov r8d, SDL_PIXELFORMAT_RGBA32
	call SDL_CreateSurface
	mov qword ptr [surface], rax

	xor rax, rax
	mov [frame_counter], rax

	call asteroids_test

	mainLoop:
		call SDL_GetTicks
		mov qword ptr [ticks], rax

		xor al, al
		mov [keys_down].fire, al
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
			jne @f
				mov [keys_down].up, 1
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_S
			jne @f
				mov [keys_down].down, 1
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_A
			jne @f
				mov [keys_down].left, 1
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_D
			jne @f
				mov [keys_down].right, 1
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_Q
			je quit
			keyDownCheckEnd:

			cmp [event].SDL_Event.event_type, SDL_EVENT_KEY_UP
			jne keyUpCheckEnd
			; which key was pressed?
			mov eax, [event].SDL_KeyboardEvent.key
			cmp eax, SDLK_W
			jne @f
				mov [keys_down].up, 0
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_S
			jne @f
				mov [keys_down].down, 0
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_A
			jne @f
				mov [keys_down].left, 0
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_D
			jne @f
				mov [keys_down].right, 0
				jmp pollLoopNext
			@@:
			cmp eax, SDLK_SPACE
			jne @f
				mov [keys_down].fire, 1
			@@:
			keyUpCheckEnd:


			pollLoopNext:
			jmp pollLoop
		pollLoopEnd:

		call clearPixelBuffer

		lea rdi, keys_down
		call ship_update
		call ship_draw

		call bullets_updateAll
		call asteroids_updateAll
		call fire_updateAll

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
	mov rcx, [window]
	call SDL_DestroyWindow
	mov rcx, [renderer]
	call SDL_DestroyRenderer
	mov rcx, [surface]
	call SDL_DestroySurface
	call SDL_Quit

	mov rsp, rbp
	pop rbp
	xor eax, eax
	ret
main endp

end
