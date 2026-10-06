default rel
%include "syscalls.inc"

global _start

section .data
uname_all db "Hinux depth 6.8.0-hinux-rt #1 SMP PREEMPT_DYNAMIC x86_64 Hinux/Depth", 10
uname_all_len equ $ - uname_all
uname_s db "Hinux", 10
uname_s_len equ $ - uname_s
uname_m db "x86_64", 10
uname_m_len equ $ - uname_m

section .text

_start:
    mov r12, [rsp]
    cmp r12, 1
    jle .print_s

    mov rdi, [rsp + 16]
    cmp byte [rdi], '-'
    jne .print_s
    mov al, byte [rdi + 1]
    cmp al, 'a'
    je .print_all
    cmp al, 'm'
    je .print_m

.print_s:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [uname_s]
    mov rdx, uname_s_len
    syscall
    jmp .exit

.print_all:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [uname_all]
    mov rdx, uname_all_len
    syscall
    jmp .exit

.print_m:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [uname_m]
    mov rdx, uname_m_len
    syscall

.exit:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
