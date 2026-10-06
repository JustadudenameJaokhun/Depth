default rel
%include "syscalls.inc"

global _start

section .bss
cpbuf resb 65536

section .text

_start:
    mov r12, [rsp]
    cmp r12, 3
    jne .err

    mov rdi, [rsp + 16]
    xor rsi, rsi
    xor rdx, rdx
    mov rax, SYS_OPEN
    syscall
    test rax, rax
    js .err
    mov r13, rax

    mov rdi, [rsp + 24]
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 420
    mov rax, SYS_OPEN
    syscall
    test rax, rax
    js .err_close_src
    mov r14, rax

.copy_loop:
    mov rax, SYS_READ
    mov rdi, r13
    lea rsi, [cpbuf]
    mov rdx, 65536
    syscall
    test rax, rax
    jle .done_copy
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, r14
    lea rsi, [cpbuf]
    syscall
    jmp .copy_loop

.done_copy:
    mov rax, SYS_CLOSE
    mov rdi, r14
    syscall
    mov rax, SYS_CLOSE
    mov rdi, r13
    syscall
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.err_close_src:
    mov rax, SYS_CLOSE
    mov rdi, r13
    syscall

.err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
