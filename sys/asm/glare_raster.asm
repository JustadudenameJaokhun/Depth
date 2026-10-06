default rel

global glare_draw_line_bresenham
global glare_draw_circle_bresenham
global glare_draw_filled_circle
global glare_render_bezier_curve

section .text

glare_draw_line_bresenham:
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

    mov eax, r8d
    sub eax, r14d
    mov ebx, eax
    cdq
    xor eax, edx
    sub eax, edx
    mov r10d, eax

    mov eax, r9d
    sub eax, r15d
    mov ecx, eax
    cdq
    xor eax, edx
    sub eax, edx
    mov r11d, eax

    mov edx, 1
    test ebx, ebx
    jns .sx_ok
    neg edx
.sx_ok:
    mov ebx, edx

    mov edx, 1
    test ecx, ecx
    jns .sy_ok
    neg edx
.sy_ok:
    mov ecx, edx

    mov eax, r10d
    sub eax, r11d
    mov esi, eax

.plot_loop:
    movsxd rax, r15d
    imul rax, r13
    add rax, r14
    mov dword [r12 + rax*4], 0x00FFFFFF

    cmp r14d, r8d
    jne .continue_plot
    cmp r15d, r9d
    je .line_done

.continue_plot:
    mov eax, esi
    shl eax, 1

    mov edx, r11d
    neg edx
    cmp eax, edx
    jle .chk_dy
    sub esi, r11d
    add r14d, ebx

.chk_dy:
    cmp eax, r10d
    jge .plot_loop
    add esi, r10d
    add r15d, ecx
    jmp .plot_loop

.line_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

glare_draw_circle_bresenham:
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

    xor ebx, ebx
    mov eax, 3
    mov edx, r8d
    shl edx, 1
    sub eax, edx

.circle_loop:
    cmp ebx, r8d
    jg .circle_done

    inc ebx
    test eax, eax
    js .d_neg

    dec r8d
    mov edx, ebx
    sub edx, r8d
    shl edx, 2
    add edx, 10
    add eax, edx
    jmp .circle_loop

.d_neg:
    mov edx, ebx
    shl edx, 2
    add edx, 6
    add eax, edx
    jmp .circle_loop

.circle_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

glare_draw_filled_circle:
    ret

glare_render_bezier_curve:
    ret
