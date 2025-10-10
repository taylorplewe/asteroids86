ifndef sdl_defs_h
sdl_defs_h = 1


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
extern SDL_RenderTexture            : proto :ptr, :ptr, :ptr, :ptr
extern SDL_RenderClear              : proto :ptr
extern SDL_RenderPresent            : proto :ptr
extern SDL_LockSurface              : proto :ptr
extern SDL_UnlockSurface            : proto :ptr
SDL_INIT_VIDEO = 20h

SDL_EVENT_QUIT     = 100h
SDL_EVENT_KEY_DOWN = 300h
SDL_EVENT_KEY_UP   = 301h

SDLK_W     = 77h
SDLK_A     = 61h
SDLK_S     = 73h
SDLK_D     = 64h
SDLK_SPACE = 20h
SDLK_Q     = 71h

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


endif
