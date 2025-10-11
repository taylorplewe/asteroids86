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
  - `MyStruct`
  - `MyUnion`
  - `my_struct_member`
  - `my_variable`
  - `myProcedure`
  - `myMacro`
  - `myCodeLabel`
  - `MY_CONSTANT`
- Since MASM has no concept of namespaces/custom scopes, each symbol pattern in a file must follow the pattern:

  `<filename>_<symbolname>`

  For example:

  `ship_updateAll`
- Contiguous definitions (no empty line separating them) of the same definition syntax should have all their columns aligned.
  - Good:
  ```
Ship struct
	x           dd     ?   ; 16.16 fixed point
	y           dd     ?   ; 16.16 fixed point
	rot         db     ?
	is_boosting db     ?
	velocity    Vector <?> ; 16.16 fixed point
Ship ends
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
  ```
