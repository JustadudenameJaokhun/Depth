default rel

global glare_sort_windows_zorder
global glare_check_overlap
global glare_damage_rect
global glare_clip_viewport
global glare_draw_halfblock_quad

section .text

glare_sort_windows_zorder:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi
    mov r13d, esi

    test r13d, r13d
    jle .sort_done

    xor ebx, ebx
.outer_loop:
    mov eax, r13d
    dec eax
    cmp ebx, eax
    jge .sort_done

    xor ecx, ecx
.inner_loop:
    mov eax, r13d
    dec eax
    sub eax, ebx
    cmp ecx, eax
    jge .next_outer

    movsxd r8, ecx
    shl r8, 5
    lea r14, [r12 + r8]
    lea r15, [r14 + 32]

    mov eax, dword [r14 + 20]
    mov edx, dword [r15 + 20]
    cmp eax, edx
    jle .no_swap

    xor r9d, r9d
.swap_loop:
    cmp r9d, 8
    jge .no_swap
    mov eax, dword [r14 + r9*4]
    mov edx, dword [r15 + r9*4]
    mov dword [r14 + r9*4], edx
    mov dword [r15 + r9*4], eax
    inc r9d
    jmp .swap_loop

.no_swap:
    inc ecx
    jmp .inner_loop

.next_outer:
    inc ebx
    jmp .outer_loop

.sort_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

glare_check_overlap:
    mov eax, edi
    mov ecx, edx
    mov r8d, dword [rsp + 8]
    mov r9d, dword [rsp + 16]

    cmp eax, r8d
    jge .no_overlap
    add eax, esi
    cmp eax, r8d
    jle .no_overlap

    cmp ecx, r9d
    jge .no_overlap
    mov r10d, dword [rsp + 24]
    add ecx, r10d
    cmp ecx, r9d
    jle .no_overlap

    mov eax, 1
    ret

.no_overlap:
    xor eax, eax
    ret

glare_damage_rect:
    push rbp
    mov rbp, rsp
    mov eax, edi
    cmp eax, edx
    cmovg eax, edx
    mov ecx, esi
    cmp ecx, r8d
    cmovg ecx, r8d
    mov dword [r9], eax
    mov dword [r9 + 4], ecx
    leave
    ret

glare_clip_viewport:
    push rbp
    mov rbp, rsp
    test edi, edi
    jns .x_ok
    xor edi, edi
.x_ok:
    test esi, esi
    jns .y_ok
    xor esi, esi
.y_ok:
    mov eax, edi
    add eax, edx
    cmp eax, r8d
    jle .w_ok
    mov edx, r8d
    sub edx, edi
.w_ok:
    mov eax, esi
    add eax, ecx
    cmp eax, r9d
    jle .h_ok
    mov ecx, r9d
    sub ecx, esi
.h_ok:
    mov eax, edx
    leave
    ret

glare_draw_halfblock_quad:
    push rbp
    mov rbp, rsp
    mov eax, edi
    shl eax, 16
    or eax, esi
    leave
    ret
