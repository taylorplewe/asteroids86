ifndef sdl_defs_h
sdl_defs_h = 1

include <enum.inc>


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
extern SDL_GetKeyboardState         : proto
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
extern SDL_GetGamepadButton         : proto
extern SDL_GetGamepadAxis           : proto
extern SDL_RumbleGamepad            : proto
extern SDL_OpenGamepad              : proto
extern SDL_CloseGamepad             : proto
SDL_INIT_VIDEO   = 20h
SDL_INIT_GAMEPAD = 2000h

SDL_EVENT_QUIT                = 100h
SDL_EVENT_KEY_DOWN            = 300h
SDL_EVENT_KEY_UP              = 301h
SDL_EVENT_GAMEPAD_AXIS_MOTION = 650h ; Gamepad axis motion
SDL_EVENT_GAMEPAD_BUTTON_DOWN = 651h ; Gamepad button pressed
SDL_EVENT_GAMEPAD_BUTTON_UP   = 652h ; Gamepad button released

SDLK_Q     = 71h

SDL_SCANCODE_A      = 4
SDL_SCANCODE_D      = 7
SDL_SCANCODE_L      = 15
SDL_SCANCODE_Q      = 20
SDL_SCANCODE_S      = 22
SDL_SCANCODE_W      = 26

SDL_SCANCODE_ESCAPE = 41
SDL_SCANCODE_SPACE  = 44

SDL_SCANCODE_RIGHT  = 79
SDL_SCANCODE_LEFT   = 80
SDL_SCANCODE_DOWN   = 81
SDL_SCANCODE_UP     = 82

SDL_PIXELFORMAT_RGBA32 = 376840196 ; idk

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

SDL_SCALEMODE_NEAREST = 0

; https://wiki.libsdl.org/SDL3/SDL_GamepadButton
enum SDL_GamepadButton, noscope
    emem SDL_GAMEPAD_BUTTON_SOUTH           ; Bottom face button (e.g. Xbox A button)
    emem SDL_GAMEPAD_BUTTON_EAST            ; Right face button (e.g. Xbox B button)
    emem SDL_GAMEPAD_BUTTON_WEST            ; Left face button (e.g. Xbox X button)
    emem SDL_GAMEPAD_BUTTON_NORTH           ; Top face button (e.g. Xbox Y button)
    emem SDL_GAMEPAD_BUTTON_BACK
    emem SDL_GAMEPAD_BUTTON_GUIDE
    emem SDL_GAMEPAD_BUTTON_START
    emem SDL_GAMEPAD_BUTTON_LEFT_STICK
    emem SDL_GAMEPAD_BUTTON_RIGHT_STICK
    emem SDL_GAMEPAD_BUTTON_LEFT_SHOULDER
    emem SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER
    emem SDL_GAMEPAD_BUTTON_DPAD_UP
    emem SDL_GAMEPAD_BUTTON_DPAD_DOWN
    emem SDL_GAMEPAD_BUTTON_DPAD_LEFT
    emem SDL_GAMEPAD_BUTTON_DPAD_RIGHT
    emem SDL_GAMEPAD_BUTTON_MISC1           ; Additional button (e.g. Xbox Series X share button, PS5 microphone button, Nintendo Switch Pro capture button, Amazon Luna microphone button, Google Stadia capture button)
    emem SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1   ; Upper or primary paddle, under your right hand (e.g. Xbox Elite paddle P1, DualSense Edge RB button, Right Joy-Con SR button)
    emem SDL_GAMEPAD_BUTTON_LEFT_PADDLE1    ; Upper or primary paddle, under your left hand (e.g. Xbox Elite paddle P3, DualSense Edge LB button, Left Joy-Con SL button)
    emem SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2   ; Lower or secondary paddle, under your right hand (e.g. Xbox Elite paddle P2, DualSense Edge right Fn button, Right Joy-Con SL button)
    emem SDL_GAMEPAD_BUTTON_LEFT_PADDLE2    ; Lower or secondary paddle, under your left hand (e.g. Xbox Elite paddle P4, DualSense Edge left Fn button, Left Joy-Con SR button)
    emem SDL_GAMEPAD_BUTTON_TOUCHPAD        ; PS4/PS5 touchpad button
    emem SDL_GAMEPAD_BUTTON_MISC2           ; Additional button
    emem SDL_GAMEPAD_BUTTON_MISC3           ; Additional button (e.g. Nintendo GameCube left trigger click)
    emem SDL_GAMEPAD_BUTTON_MISC4           ; Additional button (e.g. Nintendo GameCube right trigger click)
    emem SDL_GAMEPAD_BUTTON_MISC5           ; Additional button
    emem SDL_GAMEPAD_BUTTON_MISC6           ; Additional button
    emem SDL_GAMEPAD_BUTTON_COUNT

enum SDL_GamepadAxis, noscope
    emem SDL_GAMEPAD_AXIS_LEFTX
    emem SDL_GAMEPAD_AXIS_LEFTY
    emem SDL_GAMEPAD_AXIS_RIGHTX
    emem SDL_GAMEPAD_AXIS_RIGHTY
    emem SDL_GAMEPAD_AXIS_LEFT_TRIGGER
    emem SDL_GAMEPAD_AXIS_RIGHT_TRIGGER
    emem SDL_GAMEPAD_AXIS_COUN


endif
