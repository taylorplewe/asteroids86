# Code Patterns

Following is a list of various code patterns this codebase employs for consistency, safety, reduced headaches and cleanliness.

- *Every* procedure, which is *not* a top-level procedure called from `main`, and which clobbers ANY registers other than `rax`, MUST be bookended with pushing and popping *every one of those registers.*

  If you don't like the number of registers a procedure is pushing and popping, use a stack frame for local vars instead. But always know that using registers (even after pushing and popping them like this) is more performant.

  You may think this is wasteful and could be omitted if you're careful, but I cannot express to you how many headaches and impossible-to-track-down bugs this saves. It just makes everything safer and more contained.
  - The order in which the registers should be pushed is:
    - stack registers, if the procedure also uses a stack frame
    - `rbx`
    - `rcx`
    - `rdx`
    - `rsi`
    - `rdi`
    - `r8`-`r15`
  - Example:
	```
	fire_create proc
		push rsi
		push r9
		push r11
		push r13
		
		; ... code that clobbers rsi, r9, r11 and r13
		
		_end: ; all code paths jump here to exit instead of using ret
		pop r13
		pop r11
		pop r9
		pop rsi
		ret
	fire_create endp
	```
