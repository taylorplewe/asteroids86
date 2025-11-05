
%defstr enum_name ""
%assign enum_val 0
%assign enum_noscope 0
%macro enum 1-2 ;name:req, noscope_option:=<> ; pass "noscope" to noscope_option if you do NOT want the name of the enum plus an underscore prepended to each member name
	%defstr enum_name %1
	%assign enum_val 0
	%define %1 dword ; so you can use it as a type
	%ifidn %2, "noscope"
		%assign enum_noscope 1
	%else
		%assign enum_noscope 0
	%endif
%endmacro

; %define defDynamicLabel(name, val) name equ val

%macro emem 1-2 ;name:req, val:=<>
	%defstr memname ""
	%if enum_noscope == 0
		%strcat memname enum_name, "_", %str(%1)
	%else
		%defstr memname %1
	%endif
	%if %0 > 1
		%assign enum_val %2
	%endif
	Myvarrrr equ 4
	%[memname] equ enum_val
	; defDynamicLabel(memname, enum_val)
	%assign enum_val enum_val + 1
%endmacro

enum Ben
	emem One
	emem Two
	emem Three

.code
start:
	mov eax, 4
	mov eax, Ben_One
	ret
