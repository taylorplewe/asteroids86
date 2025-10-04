
; SDL3
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
SDL_EVENT_QUIT = 100h
SDL_PIXELFORMAT_RGBA32 = 376840196 ; idk

SDL_Event struct
	event_type dd ?
SDL_Event ends

SDL_SurfaceFlags typedef dword
SDL_PixelFormat  typedef dword
SDL_Surface struct
	flags    SDL_SurfaceFlags ? ; 0
	format   SDL_PixelFormat  ? ; 4
	w        dd               ? ; 8
	h        dd               ? ; 12
	pitch    dd               ? ; 16
	    pad0 dd               ? ; 20
	pixels   dq               ? ; 24
	refcount dd               ? ; 32
	reserved dq               ? ; 36
SDL_Surface ends
