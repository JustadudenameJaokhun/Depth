default rel
%include "syscalls.inc"

global _start

section .data
space db 32
nl db 10

section .text

_start:
    mov r12, [rsp]
    lea r13, [rsp + 16]
    cmp r12, 1
    jle .end_nl
    mov r14, 1

.loop:
    cmp r14, r12
    jge .end_nl
    mov rdi, [r13]
    call print_str
    inc r14
    add r13, 8
    cmp r14, r12
    jge .loop
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [space]
    mov rdx, 1
    syscall
    jmp .loop

.end_nl:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [nl]
    mov rdx, 1
    syscall
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

print_str:
    xor rdx, rdx
.len_loop:
    cmp byte [rdi + rdx], 0
    je .len_done
    inc rdx
    jmp .len_loop
.len_done:
    test rdx, rdx
    jz .ret
    mov rsi, rdi
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
.ret:
    ret
