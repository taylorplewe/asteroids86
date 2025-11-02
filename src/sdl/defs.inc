ifndef sdl_defs_h
sdl_defs_h = 1

include <enum.inc>


extern SDL_Init                     : proto :dword
extern SDL_Quit                     : proto
extern SDL_GetTicks                 : proto
extern SDL_Delay                    : proto :dword
extern SDL_CreateWindow             : proto :ptr, :dword, :dword, :dword
extern SDL_CreateRenderer           : proto :ptr, :ptr
extern SDL_CreateSurface            : proto :dword, :dword, :dword
extern SDL_DestroyWindow            : proto :ptr
extern SDL_DestroyRenderer          : proto :ptr
extern SDL_DestroyTexture           : proto :ptr
extern SDL_DestroySurface           : proto :ptr
extern SDL_PollEvent                : proto :ptr
extern SDL_CreateTextureFromSurface : proto :ptr, :ptr
extern SDL_SetTextureScaleMode      : proto :ptr, :dword
extern SDL_RenderTexture            : proto :ptr, :ptr, :ptr, :ptr
extern SDL_RenderClear              : proto :ptr
extern SDL_RenderPresent            : proto :ptr
extern SDL_LockSurface              : proto :ptr
extern SDL_UnlockSurface            : proto :ptr
extern SDL_LoadBMP                  : proto :ptr
extern SDL_SetWindowIcon            : proto :ptr, :ptr
SDL_INIT_VIDEO   = 20h
SDL_INIT_GAMEPAD = 2000h

SDL_EVENT_QUIT     = 100h
SDL_EVENT_KEY_DOWN = 300h
SDL_EVENT_KEY_UP   = 301h

SDLK_ESC   = 1bh
SDLK_SPACE = 20h
SDLK_W     = 77h
SDLK_A     = 61h
SDLK_S     = 73h
SDLK_D     = 64h
SDLK_Q     = 71h
SDLK_L     = 6ch
SDLK_UP    = 40000052h
SDLK_DOWN  = 40000051h
SDLK_LEFT  = 40000050h
SDLK_RIGHT = 4000004fh

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
enum SDL_GamepadButton
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

enum SDL_GamepadAxis
    emem SDL_GAMEPAD_AXIS_LEFTX
    emem SDL_GAMEPAD_AXIS_LEFTY
    emem SDL_GAMEPAD_AXIS_RIGHTX
    emem SDL_GAMEPAD_AXIS_RIGHTY
    emem SDL_GAMEPAD_AXIS_LEFT_TRIGGER
    emem SDL_GAMEPAD_AXIS_RIGHT_TRIGGER
    emem SDL_GAMEPAD_AXIS_COUN


endif
