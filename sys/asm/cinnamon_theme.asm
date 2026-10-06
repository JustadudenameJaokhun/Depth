default rel

global cinnamon_get_titlebar_bg
global cinnamon_get_window_bg
global cinnamon_get_panel_bg
global cinnamon_get_accent_color
global cinnamon_calc_panel_rect
global cinnamon_calc_menu_rect
global cinnamon_blend_alpha

section .text

cinnamon_get_titlebar_bg:
    push rbp
    mov rbp, rsp
    test edi, edi
    jz .inactive_bg
    mov eax, 0x2b303a
    leave
    ret

.inactive_bg:
    mov eax, 0x1e2127
    leave
    ret

cinnamon_get_window_bg:
    push rbp
    mov rbp, rsp
    mov eax, 0x16181d
    leave
    ret

cinnamon_get_panel_bg:
    push rbp
    mov rbp, rsp
    mov eax, 0x14161a
    leave
    ret

cinnamon_get_accent_color:
    push rbp
    mov rbp, rsp
    mov eax, 0x76b852
    leave
    ret

cinnamon_calc_panel_rect:
    push rbp
    mov rbp, rsp
    mov dword [rdx], 0
    mov eax, esi
    dec eax
    mov dword [rcx], eax
    mov dword [r8], edi
    mov dword [r9], 1
    leave
    ret

cinnamon_calc_menu_rect:
    push rbp
    mov rbp, rsp
    mov dword [rdx], 1
    mov eax, esi
    sub eax, 15
    test eax, eax
    jns .y_ok
    xor eax, eax
.y_ok:
    mov dword [rcx], eax
    mov dword [r8], 36
    mov dword [r9], 14
    leave
    ret

cinnamon_blend_alpha:
    push rbp
    mov rbp, rsp
    push rbx

    movzx r8d, dl
    mov r9d, 255
    sub r9d, r8d

    mov eax, edi
    shr eax, 16
    and eax, 0xFF
    imul eax, r8d

    mov ebx, esi
    shr ebx, 16
    and ebx, 0xFF
    imul ebx, r9d

    add eax, ebx
    shr eax, 8
    shl eax, 16
    mov r10d, eax

    mov eax, edi
    shr eax, 8
    and eax, 0xFF
    imul eax, r8d

    mov ebx, esi
    shr ebx, 8
    and ebx, 0xFF
    imul ebx, r9d

    add eax, ebx
    shr eax, 8
    shl eax, 8
    or r10d, eax

    mov eax, edi
    and eax, 0xFF
    imul eax, r8d

    mov ebx, esi
    and ebx, 0xFF
    imul ebx, r9d

    add eax, ebx
    shr eax, 8
    or eax, r10d

    pop rbx
    leave
    ret
