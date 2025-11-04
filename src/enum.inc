ifndef enum_h
enum_h = 1


enum_name textequ <>
enum_val = 0
enum_noscope = 0
enum macro name:req, noscope_option:=<> ; pass "noscope" to noscope_option if you do NOT want the name of the enum plus an underscore prepended to each member name
	enum_name textequ <name>
	enum_val = 0
	name typedef dword ; so you can use it as a type
	ifidn <noscope_option>, <noscope>
		enum_noscope = 1
	else
		enum_noscope = 0
	endif
endm
emem macro name:req, val:=<>
	if enum_noscope eq 0
		memname catstr enum_name, <_>, <name>
	else
		memname textequ <name>
	endif
	if (@SizeStr(val) gt 0)
		enum_val = val
	endif
	%memname = enum_val
	enum_val = enum_val + 1
endm


endif
