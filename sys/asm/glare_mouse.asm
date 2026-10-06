default rel

global glare_parse_mouse_sgr
global glare_clip_rect
global glare_draw_hline
global glare_draw_vline

section .text

glare_parse_mouse_sgr:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13

    mov r12, rdi
    test r12, r12
    jz .err

    cmp byte [r12], 0x1B
    jne .err
    cmp byte [r12+1], '['
    jne .err
    cmp byte [r12+2], '<'
    jne .err

    lea rdi, [r12+3]
    call parse_dec
    mov dword [rsi], eax

    mov rdi, r13
    call parse_dec
    mov dword [rdx], eax

    mov rdi, r13
    call parse_dec
    mov dword [rcx], eax

    movzx eax, byte [r13]
    mov byte [r8], al

    mov eax, 1
    jmp .done

.err:
    xor eax, eax

.done:
    pop r13
    pop r12
    pop rbx
    leave
    ret

parse_dec:
    xor eax, eax
    xor ecx, ecx
.loop:
    movzx edx, byte [rdi]
    cmp dl, '0'
    jl .fin
    cmp dl, '9'
    jg .fin
    sub dl, '0'
    imul eax, eax, 10
    add eax, edx
    inc rdi
    inc ecx
    jmp .loop
.fin:
    cmp byte [rdi], ';'
    jne .no_semi
    inc rdi
.no_semi:
    mov r13, rdi
    ret

glare_clip_rect:
    mov eax, edi
    cmp eax, edx
    cmovg eax, edx
    mov r8d, esi
    cmp r8d, ecx
    cmovg r8d, ecx
    ret

glare_draw_hline:
    push rdi
    push rcx
.h_loop:
    test edx, edx
    jz .h_done
    mov byte [rdi], cl
    inc rdi
    dec edx
    jmp .h_loop
.h_done:
    pop rcx
    pop rdi
    ret

glare_draw_vline:
    push rdi
.v_loop:
    test edx, edx
    jz .v_done
    mov byte [rdi], cl
    add rdi, r8
    dec edx
    jmp .v_loop
.v_done:
    pop rdi
    ret
