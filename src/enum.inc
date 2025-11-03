ifndef enum_h
enum_h = 1


enum_name textequ <>
enum_val = 0
enum macro name:req
	enum_name textequ <name>
	enum_val = 0
	name typedef dword ; so you can use it as a type
endm
emem macro name:req, val:=<>
	memname catstr enum_name, <_>, <name>
	if (@SizeStr(val) gt 0)
		enum_val = val
	endif
	%memname = enum_val
	enum_val = enum_val + 1
endm


endif
