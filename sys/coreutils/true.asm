default rel
%include "syscalls.inc"

global _start

section .text

_start:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
