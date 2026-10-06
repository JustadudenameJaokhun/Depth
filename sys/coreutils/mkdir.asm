default rel
%include "syscalls.inc"

global _start

section .text

_start:
    mov r12, [rsp]
    cmp r12, 1
    jle .err

    mov r13, 1
    lea r14, [rsp + 16]

.loop:
    cmp r13, r12
    jge .done
    mov rdi, [r14]
    mov rsi, 493
    mov rax, SYS_MKDIR
    syscall
    test rax, rax
    js .err
    inc r13
    add r14, 8
    jmp .loop

.done:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
