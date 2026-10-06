default rel
%include "syscalls.inc"

global _start

section .data
root_str db "root", 10
root_len equ $ - root_str
user_str db "user", 10
user_len equ $ - user_str

section .text

_start:
    mov rax, SYS_GETUID
    syscall
    test rax, rax
    jnz .is_user

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [root_str]
    mov rdx, root_len
    syscall
    jmp .exit

.is_user:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [user_str]
    mov rdx, user_len
    syscall

.exit:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
