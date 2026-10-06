default rel
%include "syscalls.inc"

global _start

section .data
y_str db "y", 10

section .text

_start:
    mov r12, [rsp]
    cmp r12, 1
    jle .infinite_y

    mov rdi, [rsp + 16]
    xor rdx, rdx
.len_loop:
    cmp byte [rdi + rdx], 0
    je .loop_arg
    inc rdx
    jmp .len_loop

.loop_arg:
    mov rsi, rdi
    mov r13, rdx
.arg_infinite:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rdx, r13
    syscall
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [y_str + 1]
    mov rdx, 1
    syscall
    mov rsi, [rsp + 16]
    jmp .arg_infinite

.infinite_y:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [y_str]
    mov rdx, 2
    syscall
    jmp .infinite_y
