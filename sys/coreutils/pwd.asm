default rel
%include "syscalls.inc"

global _start

section .data
nl db 10

section .bss
pwdbuf resb 4096

section .text

_start:
    lea rdi, [pwdbuf]
    mov rsi, 4096
    mov rax, SYS_GETCWD
    syscall
    test rax, rax
    jle .err

    xor rdx, rdx
.len_loop:
    cmp byte [pwdbuf + rdx], 0
    je .len_done
    inc rdx
    jmp .len_loop

.len_done:
    mov rsi, rdi
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [nl]
    mov rdx, 1
    syscall

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
