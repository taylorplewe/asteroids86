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
msg          MSG         <>
monitor_info MONITORINFO <>
paint        PAINTSTRUCT <>
window_rect  RECT        <>
align 16
bitmap_info  BITMAPINFO  <>


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
    cmp edx, WM_PAINT
    je wm_paint

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

    wm_paint:
    mov rcx, [hwnd]
    lea rdx, window_rect
    callms GetClientRect

    ; brk
    mov rcx, [hwnd]
    lea rdx, paint
    callms BeginPaint

    mov rcx, rax
    call windows_stretch_di_bits

    mov rcx, [hwnd]
    lea rdx, paint
    callms EndPaint
    ; PAINTSTRUCT paint;
    ; HDC hdc = BeginPaint(h_wnd, &paint);
    ; int x = paint.rcPaint.left;
    ; int y = paint.rcPaint.top;
    ; int w = paint.rcPaint.right - paint.rcPaint.left;
    ; int h = paint.rcPaint.bottom - paint.rcPaint.top;
    ; win32::WindowDimensions win_dim = win32::get_window_dimension(h_wnd);
    ; display_buffer_in_window(
    ;     hdc,
    ;     win_dim.width,
    ;     win_dim.height,
    ;     &global_buf,
    ;     x,
    ;     y,
    ;     w,
    ;     h
    ; );
    ; EndPaint(h_wnd, &paint);

    ret
windows_wnd_proc endp

; creates the window
windows_init proc
    push rbp
    mov rbp, rsp
    sub rsp, 200h ; random number that should be plenty

        ; buf->bitmap_info = {
        ;     .bmiHeader = {
        ;         .biSize = sizeof(buf->bitmap_info.bmiHeader),
        ;         .biWidth = width,
        ;         .biHeight = -height,
        ;         .biPlanes = 1,
        ;         .biBitCount = 32,
        ;         .biCompression = BI_RGB,
        ;     },
        ; };

    mov [bitmap_info].bmi_header.bi_size, sizeof BITMAPINFOHEADER
    mov [bitmap_info].bmi_header.bi_width, SCREEN_WIDTH
    mov [bitmap_info].bmi_header.bi_height, -SCREEN_HEIGHT ; TODO: flip this and see if it un-breaks stuff
    mov [bitmap_info].bmi_header.bi_planes, 1
    mov [bitmap_info].bmi_header.bi_bit_count, 32
    mov [bitmap_info].bmi_header.bi_compression, BI_RGB
    mov [bitmap_info].bmi_header.bi_size_image, 0
    mov [bitmap_info].bmi_header.bi_x_pels_per_meter, 0
    mov [bitmap_info].bmi_header.bi_y_pels_per_meter, 0
    mov [bitmap_info].bmi_header.bi_clr_used, 0
    mov [bitmap_info].bmi_header.bi_clr_important, 0

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
    ; brk
    mov rsp, rbp
    pop rbp
    ret
windows_init endp

; execute message loop for window & get input
windows_update proc
    ; message loop
    _loop:
        lea rcx, msg
        xor rdx, rdx
        xor r8, r8
        xor r9, r9
        mov dword ptr [rsp + MSVC_SHADOW_SIZE], PM_REMOVE
        call PeekMessageA
        test rax, rax ; _Out_ LPMSG lpMsg
        je loop_end

        cmp [msg].message, WM_QUIT
        jne @f
            mov [is_running], 0
            jmp loop_end
        @@:

        lea rcx, msg
        call TranslateMessage

        lea rcx, msg
        call DispatchMessageA

        jmp _loop
    loop_end:

    ; while (PeekMessageA(
    ;     &msg,
    ;     0,
    ;     0,
    ;     0,
    ;     PM_REMOVE
    ; )) {
    ;     if (msg.message == WM_QUIT) is_running = false;
    ;     TranslateMessage(&msg);
    ;     DispatchMessageA(&msg);
    ; }


    _end:
    ret
windows_update endp

; draw pixels to screen
windows_draw proc
    mov rcx, [hwnd]
    lea rdx, window_rect
    call GetClientRect

    mov rcx, [hwnd]
    call GetDC
    push rax

    mov rcx, rax
    ; brk
    call windows_stretch_di_bits

    mov rcx, [hwnd]
    pop rdx
    call ReleaseDC

    ret
windows_draw endp

; in:
    ; rcx - HDC
windows_stretch_di_bits proc
    push rbp
    mov rbp, rsp
    sub rsp, 98h
    and rsp, not 8h ; align stack (StretchDIBits does a "movaps xmmword ptr" off of a stack offset so it must be aligned)

    ; rcx (HDC) = param
    xor edx, edx
    xor r8d, r8d
    mov r9d, [window_rect].right
    sub r9d, [window_rect].left
    mov r10d, [window_rect].bottom
    sub r10d, [window_rect].top
    mov dword ptr [rsp + MSVC_SHADOW_SIZE + 00h], r10d
    mov dword ptr [rsp + MSVC_SHADOW_SIZE + 08h], 0
    mov dword ptr [rsp + MSVC_SHADOW_SIZE + 10h], 0
    mov dword ptr [rsp + MSVC_SHADOW_SIZE + 18h], SCREEN_WIDTH
    mov dword ptr [rsp + MSVC_SHADOW_SIZE + 20h], SCREEN_HEIGHT
    lea rax, pixels
    mov qword ptr [rsp + MSVC_SHADOW_SIZE + 28h], rax
    lea rax, bitmap_info
    mov qword ptr [rsp + MSVC_SHADOW_SIZE + 30h], rax
    mov dword ptr [rsp + MSVC_SHADOW_SIZE + 38h], DIB_RGB_COLORS
    mov dword ptr [rsp + MSVC_SHADOW_SIZE + 40h], SRCCOPY
    call StretchDIBits

    mov rsp, rbp
    pop rbp

    ret
windows_stretch_di_bits endp

windows_deinit proc
    ret
windows_deinit endp


endif
