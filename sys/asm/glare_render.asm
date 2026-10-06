default rel

global glare_render_window_frame
global glare_fill_rect_color
global glare_blend_halfblocks
global glare_fast_memcpy_avx

section .text

glare_render_window_frame:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi
    mov r13d, esi
    mov r14d, edx
    mov r15d, ecx

    test r14d, r14d
    jle .done
    test r15d, r15d
    jle .done

    mov byte [r12], '+'
    mov eax, 1
.top_edge:
    cmp eax, r14d
    jge .top_corner
    mov byte [r12 + rax], '-'
    inc eax
    jmp .top_edge

.top_corner:
    mov byte [r12 + rax], '+'

    mov ebx, 1
.sides_loop:
    cmp ebx, r15d
    jge .bottom_row

    movsxd rax, ebx
    imul rax, r13
    mov byte [r12 + rax], '|'

    movsxd rdx, r14d
    add rax, rdx
    mov byte [r12 + rax], '|'

    inc ebx
    jmp .sides_loop

.bottom_row:
    movsxd rax, r15d
    imul rax, r13
    mov byte [r12 + rax], '+'
    mov ebx, 1
.bot_edge:
    cmp ebx, r14d
    jge .bot_corner
    add rax, rbx
    mov byte [r12 + rax], '-'
    sub rax, rbx
    inc ebx
    jmp .bot_edge

.bot_corner:
    add rax, rbx
    mov byte [r12 + rax], '+'

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

glare_fill_rect_color:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14

    mov r12, rdi
    mov r13d, edx
    mov r14d, ecx

.row_loop:
    test r14d, r14d
    jle .fill_done
    mov rdi, r12
    mov eax, r8d
    mov ecx, r13d
    rep stosd
    movsxd rax, esi
    lea r12, [r12 + rax*4]
    dec r14d
    jmp .row_loop

.fill_done:
    pop r14
    pop r13
    pop r12
    leave
    ret

glare_blend_halfblocks:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi
    mov r13, rsi

.blend_loop:
    test rdx, rdx
    jz .blend_done

    mov eax, dword [r12]
    mov ecx, dword [r13]

    mov r8d, eax
    and r8d, 0x00FF00FF
    mov r9d, ecx
    and r9d, 0x00FF00FF
    add r8d, r9d
    shr r8d, 1
    and r8d, 0x00FF00FF

    mov r10d, eax
    and r10d, 0x0000FF00
    mov r11d, ecx
    and r11d, 0x0000FF00
    add r10d, r11d
    shr r10d, 1
    and r10d, 0x0000FF00

    or r8d, r10d
    mov dword [r12], r8d

    add r12, 4
    add r13, 4
    dec rdx
    jmp .blend_loop

.blend_done:
    pop r13
    pop r12
    leave
    ret

glare_fast_memcpy_avx:
    mov rcx, rdx
    shr rcx, 5
.avx_loop:
    test rcx, rcx
    jz .tail
    vmovdqu ymm0, [rsi]
    vmovdqu [rdi], ymm0
    add rsi, 32
    add rdi, 32
    dec rcx
    jmp .avx_loop

.tail:
    mov rcx, rdx
    and rcx, 31
    rep movsb
    vzeroupper
    ret
