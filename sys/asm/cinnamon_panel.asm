default rel
%include "syscalls.inc"

global cinnamon_format_clock
global cinnamon_draw_applet_status
global cinnamon_hit_test_panel
global cinnamon_get_menu_item
global cinnamon_count_menu_items

section .data
    time_val dq 0

    m0_name db "Nemo File Manager", 0
    m0_cmd  db "nemo", 0
    m1_name db "Mozilla Firefox", 0
    m1_cmd  db "firefox", 0
    m2_name db "Depth Terminal", 0
    m2_cmd  db "sh", 0
    m3_name db "System Settings", 0
    m3_cmd  db "cinnamon-settings", 0
    m4_name db "Dive Package Hub", 0
    m4_cmd  db "dive", 0
    m5_name db "Power Off / Halt", 0
    m5_cmd  db "shutdown", 0

    menu_table:
        dq m0_name, m0_cmd
        dq m1_name, m1_cmd
        dq m2_name, m2_cmd
        dq m3_name, m3_cmd
        dq m4_name, m4_cmd
        dq m5_name, m5_cmd

    total_menu_items equ 6

section .text

cinnamon_count_menu_items:
    push rbp
    mov rbp, rsp
    mov eax, total_menu_items
    leave
    ret

cinnamon_get_menu_item:
    push rbp
    mov rbp, rsp
    cmp edi, total_menu_items
    jae .out_of_bounds

    movsxd rax, edi
    shl rax, 4
    lea rcx, [menu_table + rax]

    mov r8, [rcx]
    mov [rsi], r8
    mov r9, [rcx + 8]
    mov [rdx], r9

    mov eax, 1
    leave
    ret

.out_of_bounds:
    xor eax, eax
    leave
    ret

cinnamon_hit_test_panel:
    push rbp
    mov rbp, rsp

    cmp edi, 10
    jl .hit_menu

    cmp edi, 24
    jl .hit_nemo

    cmp edi, 40
    jl .hit_ff

    cmp edi, 58
    jl .hit_term

    cmp edi, 74
    jl .hit_settings

    mov eax, esi
    sub eax, 16
    cmp edi, eax
    jge .hit_tray

    mov dword [rdx], -1
    mov eax, 0
    leave
    ret

.hit_menu:
    mov dword [rdx], 0
    mov eax, 1
    leave
    ret

.hit_nemo:
    mov dword [rdx], 1
    mov eax, 1
    leave
    ret

.hit_ff:
    mov dword [rdx], 2
    mov eax, 1
    leave
    ret

.hit_term:
    mov dword [rdx], 3
    mov eax, 1
    leave
    ret

.hit_settings:
    mov dword [rdx], 4
    mov eax, 1
    leave
    ret

.hit_tray:
    mov dword [rdx], 5
    mov eax, 1
    leave
    ret

cinnamon_draw_applet_status:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    mov r12, rdx

    test edi, edi
    jz .net_offline
    mov byte [r12], '['
    mov byte [r12 + 1], 'N'
    mov byte [r12 + 2], 'E'
    mov byte [r12 + 3], 'T'
    mov byte [r12 + 4], ']'
    mov byte [r12 + 5], ' '
    add r12, 6
    jmp .add_vol

.net_offline:
    mov byte [r12], '['
    mov byte [r12 + 1], '-'
    mov byte [r12 + 2], '-'
    mov byte [r12 + 3], '-'
    mov byte [r12 + 4], ']'
    mov byte [r12 + 5], ' '
    add r12, 6

.add_vol:
    mov byte [r12], '['
    mov byte [r12 + 1], 'V'
    mov byte [r12 + 2], 'O'
    mov byte [r12 + 3], 'L'
    mov byte [r12 + 4], ']'
    mov byte [r12 + 5], 0

    pop r12
    pop rbx
    leave
    ret

cinnamon_format_clock:
    push rbp
    mov rbp, rsp

    lea rsi, [time_val]
    mov rax, 201
    syscall

    mov rax, [time_val]
    xor edx, edx
    mov ecx, 86400
    div ecx

    mov eax, edx
    xor edx, edx
    mov ecx, 3600
    div ecx
    mov r8d, eax

    mov eax, edx
    xor edx, edx
    mov ecx, 60
    div ecx
    mov r9d, eax

    mov eax, r8d
    xor edx, edx
    mov ecx, 10
    div ecx
    add al, '0'
    add dl, '0'
    mov byte [rdi], al
    mov byte [rdi + 1], dl
    mov byte [rdi + 2], ':'

    mov eax, r9d
    xor edx, edx
    mov ecx, 10
    div ecx
    add al, '0'
    add dl, '0'
    mov byte [rdi + 3], al
    mov byte [rdi + 4], dl
    mov byte [rdi + 5], 0

    mov eax, 5
    leave
    ret
