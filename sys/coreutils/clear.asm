default rel
%include "syscalls.inc"

global _start

section .data
clear_seq db 27, "[2J", 27, "[H"
clear_len equ $ - clear_seq

section .text

_start:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [clear_seq]
    mov rdx, clear_len
    syscall

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
