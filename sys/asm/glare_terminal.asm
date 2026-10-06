default rel

global glare_term_scroll_up
global glare_term_clear_line
global glare_term_write_cell
global glare_term_draw_prompt
global glare_term_compute_cursor

section .text

glare_term_scroll_up:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    mov r12, rdi
    mov r13d, esi
    mov r14d, edx

    dec r13d
    test r13d, r13d
    jle .scroll_done

    mov eax, r13d
    imul eax, r14d
    mov ebx, eax

    lea rsi, [r12 + r14 * 8]
    mov rdi, r12
    mov ecx, ebx
    rep movsq

    mov eax, r13d
    imul eax, r14d
    lea rdi, [r12 + rax * 8]
    mov ecx, r14d
    xor eax, eax
    rep stosq

.scroll_done:
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

glare_term_clear_line:
    push rbp
    mov rbp, rsp
    push rdi

    imul esi, edx
    lea rdi, [rdi + rsi * 8]
    mov ecx, edx
    xor eax, eax
    rep stosq

    pop rdi
    leave
    ret

glare_term_write_cell:
    push rbp
    mov rbp, rsp

    imul esi, edx
    add esi, ecx
    lea rdi, [rdi + rsi * 8]

    mov word [rdi], r8w
    mov dword [rdi + 2], r9d
    mov word [rdi + 6], 0

    leave
    ret

glare_term_draw_prompt:
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
    mov r15, rcx

    xor ebx, ebx

.prompt_loop:
    movzx eax, byte [r15 + rbx]
    test al, al
    jz .prompt_done

    mov r8w, ax
    mov r9d, 0x00FF3333
    mov rdi, r12
    mov esi, r13d
    mov edx, r14d
    mov ecx, ebx
    call glare_term_write_cell

    inc ebx
    jmp .prompt_loop

.prompt_done:
    mov eax, ebx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

glare_term_compute_cursor:
    push rbp
    mov rbp, rsp

    mov eax, edi
    imul eax, esi
    add eax, edx

    leave
    ret
