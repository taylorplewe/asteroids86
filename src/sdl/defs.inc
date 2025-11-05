%ifndef sdl_defs_h
%define sdl_defs_h


extern SDL_Init                     : proto
extern SDL_Quit                     : proto
extern SDL_GetTicks                 : proto
extern SDL_Delay                    : proto
extern SDL_CreateWindow             : proto
extern SDL_CreateRenderer           : proto
extern SDL_CreateSurface            : proto
extern SDL_DestroyWindow            : proto
extern SDL_DestroyRenderer          : proto
extern SDL_DestroyTexture           : proto
extern SDL_DestroySurface           : proto
extern SDL_PollEvent                : proto
extern SDL_CreateTextureFromSurface : proto
extern SDL_SetTextureScaleMode      : proto
extern SDL_RenderTexture            : proto
extern SDL_RenderClear              : proto
extern SDL_RenderPresent            : proto
extern SDL_LockSurface              : proto
extern SDL_UnlockSurface            : proto
extern SDL_LoadBMP                  : proto
extern SDL_SetWindowIcon            : proto
; gamepads
extern SDL_free                     : proto
extern SDL_GetGamepads              : proto
extern SDL_RumbleGamepad            : proto
extern SDL_OpenGamepad              : proto
extern SDL_CloseGamepad             : proto
SDL_INIT_VIDEO   equ 20h
SDL_INIT_GAMEPAD equ 2000h

SDL_EVENT_QUIT                equ 100h
SDL_EVENT_KEY_DOWN            equ 300h
SDL_EVENT_KEY_UP              equ 301h
SDL_EVENT_GAMEPAD_AXIS_MOTION equ 650h ; Gamepad axis motion
SDL_EVENT_GAMEPAD_BUTTON_DOWN equ 651h ; Gamepad button pressed
SDL_EVENT_GAMEPAD_BUTTON_UP   equ 652h ; Gamepad button released

SDLK_ESC   equ 1bh
SDLK_SPACE equ 20h
SDLK_W     equ 77h
SDLK_A     equ 61h
SDLK_S     equ 73h
SDLK_D     equ 64h
SDLK_Q     equ 71h
SDLK_L     equ 6ch
SDLK_UP    equ 40000052h
SDLK_DOWN  equ 40000051h
SDLK_LEFT  equ 40000050h
SDLK_RIGHT equ 4000004fh

SDL_PIXELFORMAT_RGBA32 equ 376840196 ; idk

SDL_Event struct
	event_type dd ?
SDL_Event ends

SDL_KeyboardEvent struct
	event_type dd ? ; 0
	reserved   dd ? ; 4
	timestamp  dq ? ; 8
	windowID   dd ? ; 16
	which      dd ? ; 20
	scancode   dd ? ; 24
	key        dd ? ; 28
	; ... more that idc about
SDL_KeyboardEvent ends

; https://wiki.libsdl.org/SDL3/SDL_GamepadButtonEvent
SDL_GamepadButtonEvent struct
	event_type dd ?
	reserved   dd ?
	timestamp  dq ?
	which      dd ? ; JoystickId
	button     db ?
	down       db ? ; bool
	           db ?
			   db ?
SDL_GamepadButtonEvent ends

; https://wiki.libsdl.org/SDL3/SDL_GamepadAxisEvent
SDL_GamepadAxisEvent struct
	event_type dd ?
	reserved   dd ?
	timestamp  dq ?
	which      dd ? ; JoystickID
	axis       db ? ; SDL_GamepadAxis
	           db ?
			   db ?
			   db ?
	value      dw ? ; signed
	           dw ?
SDL_GamepadAxisEvent ends

SDL_SurfaceFlags typedef dword
SDL_PixelFormat  typedef dword
SDL_Surface struct
	flags    SDL_SurfaceFlags ? ; 0
	format   SDL_PixelFormat  ? ; 4
	w        dd               ? ; 8
	h        dd               ? ; 12
	pitch    dd               ? ; 16
	         dd               ? ; 20
	pixels   dq               ? ; 24
	refcount dd               ? ; 32
	reserved dq               ? ; 36
SDL_Surface ends

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
SDL_GAMEPAD_BUTTON_LEFT_STICK     equ 6
SDL_GAMEPAD_BUTTON_RIGHT_STICK    equ 7
SDL_GAMEPAD_BUTTON_LEFT_SHOULDER  equ 8
SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER equ 9
SDL_GAMEPAD_BUTTON_DPAD_UP        equ 10
SDL_GAMEPAD_BUTTON_DPAD_DOWN      equ 11
SDL_GAMEPAD_BUTTON_DPAD_LEFT      equ 12
SDL_GAMEPAD_BUTTON_DPAD_RIGHT     equ 13
SDL_GAMEPAD_BUTTON_MISC1          equ 14           ; Additional button (e.g. Xbox Series X share button, PS5 microphone button, Nintendo Switch Pro capture button, Amazon Luna microphone button, Google Stadia capture button)
SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1  equ 15   ; Upper or primary paddle, under your right hand (e.g. Xbox Elite paddle P1, DualSense Edge RB button, Right Joy-Con SR button)
SDL_GAMEPAD_BUTTON_LEFT_PADDLE1   equ 16    ; Upper or primary paddle, under your left hand (e.g. Xbox Elite paddle P3, DualSense Edge LB button, Left Joy-Con SL button)
SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2  equ 17   ; Lower or secondary paddle, under your right hand (e.g. Xbox Elite paddle P2, DualSense Edge right Fn button, Right Joy-Con SL button)
SDL_GAMEPAD_BUTTON_LEFT_PADDLE2   equ 18    ; Lower or secondary paddle, under your left hand (e.g. Xbox Elite paddle P4, DualSense Edge left Fn button, Left Joy-Con SR button)
SDL_GAMEPAD_BUTTON_TOUCHPAD       equ 19        ; PS4/PS5 touchpad button
SDL_GAMEPAD_BUTTON_MISC2          equ 20           ; Additional button
SDL_GAMEPAD_BUTTON_MISC3          equ 21           ; Additional button (e.g. Nintendo GameCube left trigger click)
SDL_GAMEPAD_BUTTON_MISC4          equ 22           ; Additional button (e.g. Nintendo GameCube right trigger click)
SDL_GAMEPAD_BUTTON_MISC5          equ 23           ; Additional button
SDL_GAMEPAD_BUTTON_MISC6          equ 24           ; Additional button
SDL_GAMEPAD_BUTTON_COUNT          equ 25

%define SDL_GamepadAxis dd
SDL_GAMEPAD_AXIS_LEFTX         equ 0
SDL_GAMEPAD_AXIS_LEFTY         equ 1
SDL_GAMEPAD_AXIS_RIGHTX        equ 2
SDL_GAMEPAD_AXIS_RIGHTY        equ 3
SDL_GAMEPAD_AXIS_LEFT_TRIGGER  equ 4
SDL_GAMEPAD_AXIS_RIGHT_TRIGGER equ 5
SDL_GAMEPAD_AXIS_COUN          equ 6


%endif
