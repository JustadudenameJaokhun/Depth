default rel
%include "syscalls.inc"

SYS_SYNC equ 162

global _start

section .text

_start:
    mov rax, SYS_SYNC
    syscall
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
