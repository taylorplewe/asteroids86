# Style Guide

Following is the source of truth for this codebase's style of code.

- Each file `include`s all the files it needs; as opposed to `main.s` importing all files itself, in the proper order.
  - As a result, each file must be `ifndef` guarded.
- Each file may contain any number of the following sections, in order:
  - Header
    - `ifndef` guard
    - `include` statements
  - Constant definitions
    - `struct`s, `union`s, `typedef`s
    - numerical constants
  - `.data`
  - `.code`
  
  Each section is separated by 2 empty lines. `.data` and `.code` are followed by 1 empty line.
- Name casing
  - `myScope`
  - `MyStruct`
  - `MyUnion`
  - `my_struct_member`
  - `my_variable`
  - `myProcedure`
  - `myMacro`
  - `myCodeLabel`
  - `MY_CONSTANT`
- Since MASM has no concept of namespaces/custom scopes, each symbol pattern in a file must follow the pattern:

  `<scopename>_<symbolname>`

  For example:

  `ship_updateAll`
  
  `ship_setAllPoints`
  
  `ship_base_points`
- Contiguous definitions (no empty line separating them) of the same definition syntax should have all their columns aligned with spaces.
  - Good:
	```
	Ship struct
		x           dd     ?   ; 16.16 fixed point
		y           dd     ?   ; 16.16 fixed point
		rot         db     ?
		is_boosting db     ?
		velocity    Vector <?> ; 16.16 fixed point
	Ship ends

  	bullets     Bullet NUM_BULLETS dup (<>)
	bullets_len dd     0
	```
  - Bad:
	```
	Ship struct
		x dd ? ; 16.16 fixed point
		y dd ? ; 16.16 fixed point
		rot db ?
		is_boosting db ?
		velocity Vector <?> ; 16.16 fixed point
	Ship ends

  	bullets Bullet NUM_BULLETS dup (<>)
	bullets_len dd 0
	```
- Tab characters (`\t`), as opposed to spaces, to represent tabs
  - Anything where the horizontal alignment matters (like the previous point about contiguous definitions) is done with spaces
- A single space should separate *every* part of a mathematical expression:
  - Good:
	```
	mov ecx, (SCREEN_WIDTH * SCREEN_HEIGHT * 4) / 32
	```
  - Bad:
	```
	mov ecx, (SCREEN_WIDTH*SCREEN_HEIGHT*4)/32
	```
- Procedures declare their arguments (`in`) and return values (`out`) as such:
	```
	; Description of the procedure
	; in:
		; r8  - point1 (as qword ptr)
		; r10 - point2 (as qword ptr)
		; al  - rotation in 256-based radians
	; out:
		; rax - 1 if hit, 0 else
	fire_doSomething
	```
- Procedures should set the return value in `rax` *before* popping all the registers it needs to pop:
	```
		xor eax, eax
		pop rdi
		pop rcx
		pop rbx
		ret
	george_eatBanana endp
	```
- MASM's unnamed labels (`@@:`) are fine to use for short, single-level blocks. MASM itself will enforce the latter, since unlike other assemblers, it doesn't support jumping over unnamed labels to get to other unnamed labels, only the immediate next one or previous one.
	```
	dec [rdi].Bullet.ticks_to_live
	jne @f
		; destroy bullet
		mov eax, ecx
		call bullets_destroyBullet
		jmp nextCmp
	@@:
	```
- When simple words that happen to be reserved are needed, such as `loop` and `end`, it is okay to prepend them with an underscore to appease the assembler: `_loop`, `_end`.
- Omit `byte ptr`, `word ptr`, `dword ptr` and `qword ptr` unless it won't compile without them (size of memory is ambiguous or being casted to a different size)
- Use `db`, `dw`, `dd` and `dq` instead of their spelled-out alternatives
- File/scope names always refer to the singular tense of an object; "asteroid" instead of "asteroids".
  - Procedure names should *default* to operating on a single instance of the object. Otherwise, `-All` should be appended:
	```
	call asteroid_create    ; creates a single asteroid
	call asteroid_update    ; updates a single asteroid
	call asteroid_updateAll ; updates all asteroids
	```
