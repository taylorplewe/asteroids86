ifndef windows_platform_h
windows_platform_h = 1

include defs.inc


.data

class_name  db "Win32ASMTest", 0
window_name db "Win32 ASM Test", 0
debug_text  db "Hello this is from asm", 0


.data?

window_class WNDCLASS    <>
h_instance   dq          ?
hwnd         dq          ?
is_running   db          ?
msg          MSG         <>
monitor_info MONITORINFO <>
paint        PAINTSTRUCT <>


.code

; LRESULT CALLBACK main_window_callback(
;     HWND   h_wnd,
;     UINT   msg,
;     WPARAM w_param,
;     LPARAM l_param
; )
windows_wnd_proc proc
    mov [rsp + 08h], rcx
    mov [rsp + 10h], rdx
    mov [rsp + 18h], r8
    mov [rsp + 20h], r9

    cmp edx, WM_CLOSE
    je close
    cmp edx, WM_QUIT
    je close
    cmp edx, WM_KEYUP
    je keyup

    callms DefWindowProcA
    ret

    keyup:
    cmp r8, VK_ESCAPE
    jne keyup_end

    mov [is_running], 0

    keyup_end:
    xor rax, rax
    ret

    close:
    mov [is_running], 0
    ret
windows_wnd_proc endp

; creates the window
windows_init proc
    push rbp
    mov rbp, rsp
    sub rsp, 200h ; random number that should be plenty

    xor rcx, rcx
    call GetModuleHandleA
    mov [h_instance], rax

    mov [window_class].WNDCLASS.style, CS_OWNDC or CS_HREDRAW or CS_VREDRAW
    mov dword ptr [window_class].WNDCLASS.style + 4, 0
    lea rax, windows_wnd_proc
    mov [window_class].WNDCLASS.lpfn_wnd_proc, rax
    lea rax, class_name
    mov [window_class].WNDCLASS.lpsz_class_name, rax
    mov [window_class].WNDCLASS.h_instance, rcx
    mov [window_class].WNDCLASS.cb_cls_extra, 0
    mov [window_class].WNDCLASS.cb_wnd_extra, 0
    mov [window_class].WNDCLASS.h_icon, 0
    mov [window_class].WNDCLASS.h_cursor, 0
    mov [window_class].WNDCLASS.hbr_bg, 0
    mov [window_class].WNDCLASS.lpsz_menu_name, 0

    lea rcx, window_class
    call RegisterClassA
    test eax, eax
    je _end

    xor ecx, ecx
    lea rdx, class_name
    lea r8, window_name
    ; mov r9d, WS_OVERLAPPEDWINDOW
    xor r9, r9
    mov qword ptr [rsp + MSVC_SHADOW_SIZE + 38h], 0
    mov rax, [h_instance]
    mov qword ptr [rsp + MSVC_SHADOW_SIZE + 30h], rax
    mov qword ptr [rsp + MSVC_SHADOW_SIZE + 28h], 0
    mov qword ptr [rsp + MSVC_SHADOW_SIZE + 20h], 0
    mov dword ptr [rsp + MSVC_SHADOW_SIZE + 18h], CW_USEDEFAULT
    mov dword ptr [rsp + MSVC_SHADOW_SIZE + 10h], CW_USEDEFAULT
    mov dword ptr [rsp + MSVC_SHADOW_SIZE + 08h], CW_USEDEFAULT
    mov dword ptr [rsp + MSVC_SHADOW_SIZE],       CW_USEDEFAULT
    call CreateWindowExA
    mov [hwnd], rax
    test rax, rax
    je win_error

    ; fullscreen
    mov [monitor_info].cb_size, sizeof MONITORINFO

    mov rcx, [hwnd]
    mov edx, MONITOR_DEFAULTTOPRIMARY
    call MonitorFromWindow

    mov rcx, rax
    lea rdx, monitor_info
    call GetMonitorInfoA
    test rax, rax
    je fullscreen_end

    mov rcx, [hwnd]
    mov edx, GWL_STYLE
    mov r8d, WS_VISIBLE
    ; xor r8, r8
    call SetWindowLongA

    mov rcx, [hwnd]
    mov rdx, HWND_TOP
    mov r8d, [monitor_info].rc_monitor.left
    mov r9d, [monitor_info].rc_monitor.top
    mov eax, [monitor_info].rc_monitor.right
    sub eax, [monitor_info].rc_monitor.left
    mov qword ptr [rsp + MSVC_SHADOW_SIZE + 00h], rax
    mov eax, [monitor_info].rc_monitor.bottom
    sub eax, [monitor_info].rc_monitor.top
    mov qword ptr [rsp + MSVC_SHADOW_SIZE + 08h], rax
    mov qword ptr [rsp + MSVC_SHADOW_SIZE + 10h], SWP_FRAMECHANGED or SWP_NOOWNERZORDER
    call SetWindowPos

    fullscreen_end:

    mov rcx, [hwnd]
    mov edx, SW_MAXIMIZE
    call ShowWindow

    mov rcx, [hwnd]
    call UpdateWindow

    _end:
    mov rsp, rbp
    pop rbp
    ret

    win_error:
    brk
    mov rsp, rbp
    pop rbp
    ret
windows_init endp

windows_deinit proc
    ret
windows_deinit endp


endif
