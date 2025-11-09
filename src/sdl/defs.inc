%ifndef sdl_defs_h
%define sdl_defs_h


extern SDL_Init
extern SDL_Quit
extern SDL_GetTicks
extern SDL_Delay
extern SDL_CreateWindow
extern SDL_CreateRenderer
extern SDL_CreateSurface
extern SDL_DestroyWindow
extern SDL_DestroyRenderer
extern SDL_DestroyTexture
extern SDL_DestroySurface
extern SDL_PollEvent
extern SDL_GetKeyboardState
extern SDL_CreateTextureFromSurface
extern SDL_SetTextureScaleMode
extern SDL_RenderTexture
extern SDL_RenderClear
extern SDL_RenderPresent
extern SDL_LockSurface
extern SDL_UnlockSurface
extern SDL_LoadBMP
extern SDL_SetWindowIcon
; gamepads
extern SDL_free
extern SDL_GetGamepads
extern SDL_GetGamepadButton
extern SDL_GetGamepadAxis
extern SDL_RumbleGamepad
extern SDL_OpenGamepad
extern SDL_CloseGamepad
SDL_INIT_VIDEO   equ 20h
SDL_INIT_GAMEPAD equ 2000h

SDL_EVENT_QUIT                equ 100h
SDL_EVENT_KEY_DOWN            equ 300h
SDL_EVENT_KEY_UP              equ 301h
SDL_EVENT_GAMEPAD_AXIS_MOTION equ 650h ; Gamepad axis motion
SDL_EVENT_GAMEPAD_BUTTON_DOWN equ 651h ; Gamepad button pressed
SDL_EVENT_GAMEPAD_BUTTON_UP   equ 652h ; Gamepad button released

SDLK_Q     equ 71h

SDL_SCANCODE_A      equ 4
SDL_SCANCODE_D      equ 7
SDL_SCANCODE_L      equ 15
SDL_SCANCODE_Q      equ 20
SDL_SCANCODE_S      equ 22
SDL_SCANCODE_W      equ 26

SDL_SCANCODE_ESCAPE equ 41
SDL_SCANCODE_SPACE  equ 44

SDL_SCANCODE_RIGHT  equ 79
SDL_SCANCODE_LEFT   equ 80
SDL_SCANCODE_DOWN   equ 81
SDL_SCANCODE_UP     equ 82

SDL_PIXELFORMAT_RGBA32 equ 376840196 ; idk

struc SDL_Event
	.event_type: resd 1
endstruc

struc SDL_KeyboardEvent
	.event_type: resd 1 ; 0
	.reserved:   resd 1 ; 4
	.timestamp:  resq 1 ; 8
	.windowID:   resd 1 ; 16
	.which:      resd 1 ; 20
	.scancode:   resd 1 ; 24
	.key:        resd 1 ; 28
	; ... more that idc about
endstruc

; https://wiki.libsdl.org/SDL3/SDL_GamepadButtonEvent
struc SDL_GamepadButtonEvent
	.event_type: resd 1
	.reserved:   resd 1
	.timestamp:  resq 1
	.which:      resd 1 ; JoystickId
	.button:     resb 1
	.down:       resb 1 ; bool
	             resb 1
			     resb 1
endstruc

; https://wiki.libsdl.org/SDL3/SDL_GamepadAxisEvent
struc SDL_GamepadAxisEvent
	.event_type: resd 1
	.reserved:   resd 1
	.timestamp:  resq 1
	.which:      resd 1 ; JoystickID
	.axis:       resb 1 ; SDL_GamepadAxis
	             resb 1
			     resb 1
			     resb 1
	.value:      resw 1 ; signed
	             resw 1
endstruc

struc SDL_Surface
	.flags:    resd 1 ; 0
	.format:   resd 1 ; 4
	.w:        resd 1 ; 8
	.h:        resd 1 ; 12
	.pitch:    resd 1 ; 16
	           resd 1 ; 20
	.pixels:   resq 1 ; 24
	.refcount: resd 1 ; 32
	.reserved: resq 1 ; 36
endstruc

SDL_SCALEMODE_NEAREST equ 0

; https://wiki.libsdl.org/SDL3/SDL_GamepadButton
%define SDL_GamepadButton dd
SDL_GAMEPAD_BUTTON_SOUTH          equ 0           ; Bottom face button (e.g. Xbox A button)
SDL_GAMEPAD_BUTTON_EAST           equ 1            ; Right face button (e.g. Xbox B button)
SDL_GAMEPAD_BUTTON_WEST           equ 2            ; Left face button (e.g. Xbox X button)
SDL_GAMEPAD_BUTTON_NORTH          equ 3           ; Top face button (e.g. Xbox Y button)
SDL_GAMEPAD_BUTTON_BACK           equ 4
SDL_GAMEPAD_BUTTON_GUIDE          equ 5
SDL_GAMEPAD_BUTTON_START          equ 6
SDL_GAMEPAD_BUTTON_LEFT_STICK     equ 7
SDL_GAMEPAD_BUTTON_RIGHT_STICK    equ 8
SDL_GAMEPAD_BUTTON_LEFT_SHOULDER  equ 9
SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER equ 10
SDL_GAMEPAD_BUTTON_DPAD_UP        equ 11
SDL_GAMEPAD_BUTTON_DPAD_DOWN      equ 12
SDL_GAMEPAD_BUTTON_DPAD_LEFT      equ 13
SDL_GAMEPAD_BUTTON_DPAD_RIGHT     equ 14
SDL_GAMEPAD_BUTTON_MISC1          equ 15           ; Additional button (e.g. Xbox Series X share button, PS5 microphone button, Nintendo Switch Pro capture button, Amazon Luna microphone button, Google Stadia capture button)
SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1  equ 16   ; Upper or primary paddle, under your right hand (e.g. Xbox Elite paddle P1, DualSense Edge RB button, Right Joy-Con SR button)
SDL_GAMEPAD_BUTTON_LEFT_PADDLE1   equ 17    ; Upper or primary paddle, under your left hand (e.g. Xbox Elite paddle P3, DualSense Edge LB button, Left Joy-Con SL button)
SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2  equ 18   ; Lower or secondary paddle, under your right hand (e.g. Xbox Elite paddle P2, DualSense Edge right Fn button, Right Joy-Con SL button)
SDL_GAMEPAD_BUTTON_LEFT_PADDLE2   equ 19    ; Lower or secondary paddle, under your left hand (e.g. Xbox Elite paddle P4, DualSense Edge left Fn button, Left Joy-Con SR button)
SDL_GAMEPAD_BUTTON_TOUCHPAD       equ 20        ; PS4/PS5 touchpad button
SDL_GAMEPAD_BUTTON_MISC2          equ 21           ; Additional button
SDL_GAMEPAD_BUTTON_MISC3          equ 22           ; Additional button (e.g. Nintendo GameCube left trigger click)
SDL_GAMEPAD_BUTTON_MISC4          equ 23           ; Additional button (e.g. Nintendo GameCube right trigger click)
SDL_GAMEPAD_BUTTON_MISC5          equ 24           ; Additional button
SDL_GAMEPAD_BUTTON_MISC6          equ 25           ; Additional button
SDL_GAMEPAD_BUTTON_COUNT          equ 26

%define SDL_GamepadAxis dd
SDL_GAMEPAD_AXIS_LEFTX         equ 0
SDL_GAMEPAD_AXIS_LEFTY         equ 1
SDL_GAMEPAD_AXIS_RIGHTX        equ 2
SDL_GAMEPAD_AXIS_RIGHTY        equ 3
SDL_GAMEPAD_AXIS_LEFT_TRIGGER  equ 4
SDL_GAMEPAD_AXIS_RIGHT_TRIGGER equ 5
SDL_GAMEPAD_AXIS_COUN          equ 6


%endif
