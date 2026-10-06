default rel

global glare_render_button
global glare_render_text_input
global glare_hit_test_widget
global glare_render_checkbox
global glare_render_progressbar

section .data
    bracket_l db "["
    bracket_r db "]"
    checked_str db "[X] "
    unchecked_str db "[ ] "
    bar_fill db "#"
    bar_empty db "-"

section .text

glare_render_button:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    mov r12, rdi
    mov r13, rsi
    mov r14d, edx

    mov byte [r12], '['
    mov byte [r12+1], ' '
    add r12, 2

    mov rdi, r13
    call strlen
    mov rcx, rax
    mov rsi, r13
    mov rdi, r12
    rep movsb
    mov r12, rdi

    mov byte [r12], ' '
    mov byte [r12+1], ']'
    mov byte [r12+2], 0

    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

glare_render_text_input:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi
    mov r13, rsi
    mov r14d, edx
    mov r15d, ecx

    mov byte [r12], '['
    inc r12

    mov rdi, r13
    call strlen
    mov rbx, rax

    mov rcx, rbx
    cmp ecx, r14d
    cmovg ecx, r14d
    mov rsi, r13
    mov rdi, r12
    rep movsb
    mov r12, rdi

    mov eax, r14d
    sub eax, ebx
    test eax, eax
    jle .end_input

    mov ecx, eax
.pad_loop:
    mov byte [r12], ' '
    inc r12
    dec ecx
    jnz .pad_loop

.end_input:
    mov byte [r12], ']'
    mov byte [r12+1], 0

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

glare_hit_test_widget:
    cmp edi, edx
    jl .miss
    cmp esi, ecx
    jl .miss

    mov eax, edx
    add eax, r8d
    cmp edi, eax
    jge .miss

    mov eax, ecx
    add eax, r9d
    cmp esi, eax
    jge .miss

    mov eax, 1
    ret

.miss:
    xor eax, eax
    ret

glare_render_checkbox:
    push rbp
    mov rbp, rsp
    test edx, edx
    jz .not_checked

    mov byte [rdi], '['
    mov byte [rdi+1], 'X'
    mov byte [rdi+2], ']'
    mov byte [rdi+3], ' '
    jmp .cb_label

.not_checked:
    mov byte [rdi], '['
    mov byte [rdi+1], ' '
    mov byte [rdi+2], ']'
    mov byte [rdi+3], ' '

.cb_label:
    add rdi, 4
    push rdi
    mov rdi, rsi
    call strlen
    mov rcx, rax
    pop rdi
    rep movsb
    mov byte [rdi], 0

    leave
    ret

glare_render_progressbar:
    push rbp
    mov rbp, rsp
    mov byte [rdi], '['
    inc rdi

    mov eax, edx
    imul eax, ecx
    xor edx, edx
    mov ebx, 100
    div ebx
    mov r8d, eax

    xor edx, edx
.bar_loop:
    cmp edx, ecx
    jge .bar_fin

    cmp edx, r8d
    jl .draw_hash
    mov byte [rdi], '-'
    jmp .next_bar

.draw_hash:
    mov byte [rdi], '='

.next_bar:
    inc rdi
    inc edx
    jmp .bar_loop

.bar_fin:
    mov byte [rdi], ']'
    mov byte [rdi+1], 0
    leave
    ret

strlen:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret
