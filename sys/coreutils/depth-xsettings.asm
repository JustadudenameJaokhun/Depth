global _start

section .data
    timespec:
        dq 60
        dq 0

section .text

_start:
    mov rax, 57
    syscall
    test rax, rax
    jnz .parent_exit
    js .direct_run

    mov rax, 112
    syscall

.direct_run:
    mov rax, 33
    xor rdi, rdi
    syscall
    mov rax, 33
    mov rdi, 1
    syscall
    mov rax, 33
    mov rdi, 2
    syscall

.loop:
    mov rax, 35
    mov rdi, timespec
    xor rsi, rsi
    syscall
    jmp .loop

.parent_exit:
    xor edi, edi
    mov eax, 60
    syscall
