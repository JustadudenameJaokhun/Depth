default rel
%include "syscalls.inc"

global _start

section .data
nl db 10
dot db ".", 10
root_str db "/", 10

section .text

_start:
    mov r12, [rsp]
    cmp r12, 1
    jle .err

    mov rdi, [rsp + 16]
    xor rdx, rdx
    mov r13, -1

.scan:
    mov al, byte [rdi + rdx]
    test al, al
    jz .done_scan
    cmp al, '/'
    jne .not_s
    mov r13, rdx
.not_s:
    inc rdx
    jmp .scan

.done_scan:
    cmp r13, -1
    je .print_dot
    cmp r13, 0
    je .print_root

    mov rsi, rdi
    mov rdx, r13
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [nl]
    mov rdx, 1
    syscall
    jmp .exit_ok

.print_dot:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [dot]
    mov rdx, 2
    syscall
    jmp .exit_ok

.print_root:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [root_str]
    mov rdx, 2
    syscall

.exit_ok:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.err:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
