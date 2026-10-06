default rel
%include "syscalls.inc"

global _start

section .data
nl db 10

section .text

_start:
    mov r12, [rsp]
    cmp r12, 1
    jle .err

    mov rdi, [rsp + 16]
    xor rsi, rsi
    xor rdx, rdx

.find_last_slash:
    mov al, byte [rdi + rdx]
    test al, al
    jz .slash_found
    cmp al, '/'
    jne .not_slash
    lea rsi, [rdi + rdx + 1]
.not_slash:
    inc rdx
    jmp .find_last_slash

.slash_found:
    test rsi, rsi
    cmovz rsi, rdi

    mov rdi, rsi
    xor rdx, rdx
.len_loop:
    cmp byte [rdi + rdx], 0
    je .print
    inc rdx
    jmp .len_loop

.print:
    mov rsi, rdi
    mov rax, SYS_WRITE
    mov rdi, STDOUT
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
