default rel
%include "syscalls.inc"

global _start

section .text

_start:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
